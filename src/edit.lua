local conductor = require 'src.conductor'
local xdrv      = require 'lib.xdrv'
local logs      = require 'src.logs'
local clipboard = require 'src.clipboard'
local self      = {}

---@enum Mode
self.Mode       = {
  -- Technically not a mode. Implies write = false
  None = 0,
  -- ArrowVortex-style insert mode. Press a key to set or unset a note.
  Insert = 1,
  -- Move forward after adding a note.
  Append = 2,
  -- Move to the next row and overwrite the last after adding a note.
  Rewrite = 3,
}

---@param mode Mode
function self.modeName(mode)
  if mode == self.Mode.None then return 'None' end
  if mode == self.Mode.Insert then return 'Insert' end
  if mode == self.Mode.Append then return 'Append' end
  if mode == self.Mode.Rewrite then return 'Rewrite' end
end

---@type XDRVThing[]
self.selection = {}

function self.clearSelection()
  self.selection = {}
end

---@type Mode
local mode = self.Mode.Insert
self.write = false
self.quantIndex = 1

self.viewBinds = false

function self.cycleMode()
  if self.write then
    mode = mode + 1
    if mode > self.Mode.Rewrite then
      mode = 1
    end
  else
    self.write = true
  end
end

function self.getMode()
  if not self.write then return self.Mode.None end
  return mode
end

local function getBeat()
  return quantize(conductor.beat, self.quantIndex)
end
local function setBeat(b)
  conductor.seekBeats(quantize(b, self.quantIndex))
  self.updateGhosts()
  conductor.initStates()
end
function self.moveByQuant(mult)
  setBeat(conductor.beat + QUANTS[self.quantIndex] * mult)
end

function self.move(beat)
  setBeat(conductor.beat + beat)
end

function self.setQuantIndex(idx)
  self.quantIndex = math.min(math.max(idx, 1), #QUANTS)
  events.redraw()
end

---@type (XDRVNote | XDRVGearShift)[]
local ghosts = {}

function self.getGhosts()
  local saneGhosts = {}

  for _, ghost in ipairs(ghosts) do
    if ghost.note then
      local beat = ghost.beat
      local length = ghost.note.length or 0
      if length < 0 then
        beat = beat + length
        length = -length
      end
      if length == 0 then
        ---@diagnostic disable-next-line: cast-local-type
        length = nil
      end
      table.insert(saneGhosts, {
        beat = beat,
        note = { column = ghost.note.column, length = length },
      })
    elseif ghost.gearShift then
      local beat = ghost.beat
      local length = ghost.gearShift.length
      if length < 0 then
        beat = beat + length
        length = -length
      end
      table.insert(saneGhosts, {
        beat = beat,
        gearShift = { lane = ghost.gearShift.lane, length = length },
      })
    end
  end

  return saneGhosts
end

---@param column XDRVNoteColumn
function self.beginNote(column)
  if not self.write then return end

  self.clearSelection()

  local beat = getBeat()

  if mode == self.Mode.Insert or mode == self.Mode.Append then
    local thing = { beat = beat, note = { column = column } }
    local thingIdx = chart.findThing(thing)
    if thingIdx then
      chart.removeThing(thingIdx)
      logs.log('Removed note')
      chart.insertHistory('Remove note')
    else
      table.insert(ghosts, thing)
    end
    if mode == self.Mode.Append then
      self.endNote(column)
      self.move(QUANTS[self.quantIndex])
    end
  elseif mode == self.Mode.Rewrite then
    local thing = { beat = beat, note = {} }
    local thingIdx = chart.findThing(thing)
    local lastIdx = thingIdx or 1
    while thingIdx do
      chart.removeThing(thingIdx)
      lastIdx = thingIdx
      thingIdx = chart.findThing(thing)
    end
    local placed = { beat = beat, note = { column = column } }
    table.insert(ghosts, placed)
    for i = lastIdx, #chart.chart do
      local ev = chart.chart[i]
      if ev.beat > beat then
        self.quantIndex = getQuantIndex(ev.beat)
        setBeat(ev.beat)
        break
      end
    end
  end
  events.redraw()
end

---@param lane XDRVLane
function self.beginGearShift(lane)
  if not self.write then return end

  self.clearSelection()

  local beat = getBeat()
  local thing = { beat = beat, gearShift = { lane = lane } }

  local thingIdx = chart.findThing(thing)

  if thingIdx then
    chart.removeThing(thingIdx)
    logs.log('Removed gear shift')
    chart.insertHistory('Remove gear shift')
  else
    table.insert(ghosts, { beat = getBeat(), gearShift = { lane = lane, length = 0 } })
  end
  events.redraw()
end

---@param dir XDRVDriftDirection
function self.placeDrift(dir)
  if not self.write then return end

  local beat = getBeat()
  local thing = { beat = beat, drift = {} }
  local thingIdx = chart.findThing(thing)
  local cmpEvent = chart.chart[thingIdx]

  if thingIdx then
    chart.removeThing(thingIdx)
  end

  if not thingIdx or cmpEvent.drift.direction ~= dir then
    chart.placeThing({ beat = beat, drift = { direction = dir } })
    chart.insertHistory('Place drift')
    logs.log(thingIdx and 'Replaced drift' or 'Placed drift')
  else
    chart.insertHistory('Remove drift')
    logs.log('Removed drift')
  end
end

function self.endNote(column)
  for i = #ghosts, 1, -1 do
    local ghost = ghosts[i]
    if ghost.note and ghost.note.column == column then
      ghost.note.length = ghost.note.length or 0
      if ghost.note.length < 0 then
        ghost.beat = ghost.beat + ghost.note.length
        ghost.note.length = math.abs(ghost.note.length)
      end
      if ghost.note.length == 0 then
        ghost.note.length = nil
      end
      chart.placeThing(ghost)
      logs.log('Placed note')
      chart.insertHistory('Place note')
      table.remove(ghosts, i)
    end
  end
end

function self.endGearShift(lane)
  for i = #ghosts, 1, -1 do
    local ghost = ghosts[i]
    if ghost.gearShift and ghost.gearShift.lane == lane then
      if ghost.gearShift.length < 0 then
        ghost.beat = ghost.beat + ghost.gearShift.length
        ghost.gearShift.length = math.abs(ghost.gearShift.length)
      end
      if ghost.gearShift.length ~= 0 then
        chart.placeThing(ghost)
        chart.insertHistory('Place gear shift')
        logs.log('Placed gear shift')
      end
      table.remove(ghosts, i)
    end
  end
end

function self.updateGhosts()
  for _, ghost in ipairs(ghosts) do
    local ev = ghost.note or ghost.gearShift
    if ev then
      ev.length = conductor.beat - ghost.beat
    end
  end
  events.redraw()
end

---@enum TransformType
self.TransformType = {
  Invalid = -1,
  MirrorAll = 0,
  MirrorNote = 1,
  MirrorGear = 2,
  MirrorDrift = 3,
  SwapTriggerBumper = 4,
  SwapFaceTrigger = 5,
  SwapFaceBumper = 6,
}

local transform_map = {
  none = { 1, 2, 3, 4, 5, 6 },
  mirror = { 6, 5, 4, 3, 2, 1 },
  trigger_bumper = { 2, 1, 3, 4, 6, 5 },
  face_trigger = { 3, 2, 1, 6, 5, 4 },
  face_bumper = { 1, 3, 2, 5, 4, 6 },
}

---@param c XDRVNoteColumn
local function mirrorColumn(c)
  return transform_map.mirror[c]
end

---@param column XDRVNoteColumn
local function SwapTriggerBumper(column)
  return transform_map.trigger_bumper[column]
end

---@param column XDRVNoteColumn
local function SwapFaceTrigger(column)
  return transform_map.face_trigger[column]
end

---@param column XDRVNoteColumn
local function SwapFaceBumper(column)
  return transform_map.face_bumper[column]
end

local transform_func = {
  [self.TransformType.MirrorAll]         = mirrorColumn,
  [self.TransformType.MirrorNote]        = mirrorColumn,
  [self.TransformType.SwapTriggerBumper] = SwapTriggerBumper,
  [self.TransformType.SwapFaceTrigger]   = SwapFaceTrigger,
  [self.TransformType.SwapFaceBumper]    = SwapFaceBumper,
}

---@param lane XDRVLane
local function mirrorLane(lane)
  return lane == xdrv.XDRVLane.Left and xdrv.XDRVLane.Right or xdrv.XDRVLane.Left
end

---@param direction XDRVDriftDirection
local function mirrorDriftDir(direction)
  if direction == xdrv.XDRVDriftDirection.Left then return xdrv.XDRVDriftDirection.Right end
  if direction == xdrv.XDRVDriftDirection.Right then return xdrv.XDRVDriftDirection.Left end
  return xdrv.XDRVDriftDirection.Neutral
end

local transform_string = {
  [self.TransformType.MirrorAll]         = 'Mirrored All %d selected objects',
  [self.TransformType.MirrorNote]        = 'Mirrored All %d selected notes',
  [self.TransformType.MirrorGear]        = 'Mirrored All %d selected gears',
  [self.TransformType.MirrorDrift]       = 'Mirrored All %d selected drifts',
  [self.TransformType.SwapTriggerBumper] = 'Swapped %d trigger and bumper note(s)',
  [self.TransformType.SwapFaceTrigger]   = 'Swapped %d face and trigger note(s)',
  [self.TransformType.SwapFaceBumper]    = 'Swapped %d face and bumper note(s)',
}

---@param type TransformType
function self.transformSelection(type)
  local affectNotes = type ~= self.TransformType.MirrorGear and type ~= self.TransformType.MirrorDrift
  local affectGear = type == self.TransformType.MirrorAll or type == self.TransformType.MirrorGear
  local affectDrift = type == self.TransformType.MirrorAll or type == self.TransformType.MirrorDrift

  local total = 0
  for _, thing in ipairs(self.selection) do
    if thing.note and affectNotes then
      thing.note.column = transform_func[type](thing.note.column)
      total = total + 1
    elseif thing.gearShift and affectGear then
      thing.gearShift.lane = mirrorLane(thing.gearShift.lane)
      total = total + 1
    elseif thing.drift and affectDrift then
      thing.drift.direction = mirrorDriftDir(thing.drift.direction)
      total = total + 1
    end
  end
  logs.log(string.format(transform_string[type], #self.selection))
  chart.insertHistory('Transform notes')
  events.redraw()
end

function self.deleteSelection()
  if not chart.loaded then return end
  for i = #chart.chart, 1, -1 do
    local thing = chart.chart[i]
    if includes(self.selection, thing) then
      table.remove(chart.chart, i)
    end
  end
  events.redraw()
end

function self.deleteKey()
  self.deleteSelection()
  logs.log('Deleted ' .. #self.selection .. ' notes')
  self.clearSelection()
  chart.insertHistory('Delete selection')
end

function self.selectAll()
  if not chart.loaded then return end
  self.clearSelection() -- bugfix by regen=Q

  for _, thing in ipairs(chart.chart) do
    table.insert(self.selection, thing)
  end
  logs.log('Selected ' .. #self.selection .. ' notes')
end

function self.turnToMines()
  local c = 0
  local hasMines = false
  local hasNotes = false
  for _, thing in ipairs(chart.chart) do
    if includes(self.selection, thing) and thing.note and not thing.note.length then
      c = c + 1
      thing.note.mine = not thing.note.mine
      if thing.note.mine then
        hasMines = true
      else
        hasNotes = true
      end
    end
  end
  local source = ''
  local target = ''
  if hasMines then
    source = 'notes'
    target = 'mines'
  end
  if hasNotes then
    source = 'mines'
    target = 'notes'
  end
  if hasNotes and hasMines then
    source = 'things'
    target = 'notes/mines'
  end
  logs.log('Turned ' .. c .. ' ' .. source .. ' to ' .. target)
  chart.insertHistory('Invert selection mines')
  events.redraw()
end

function self.undo()
  local mem = chart.undo()
  if mem then
    logs.log('Undid ' .. (mem.message or 'action'))
  else
    logs.log('Nothing to undo')
  end
end

function self.redo()
  local mem = chart.redo()
  if mem then
    logs.log('Redid ' .. (mem.message or 'action'))
  else
    logs.log('Nothing to redo')
  end
end

function self.cut()
  self.deleteSelection()
  self.copy()
end

function self.copy()
  if not chart.loaded then return end
  if #self.selection == 0 then
    logs.log('Nothing to copy')
    love.system.setClipboardText('')
    return
  end

  local text = clipboard.encode(self.selection)

  love.system.setClipboardText(text)
  local chk = love.system.getClipboardText()
  if text ~= chk then
    logs.log('System clipboard unavailable?')
  end

  logs.log('Copied ' .. #self.selection .. ' things')
  self.clearSelection()
end

function self.hasSomethingToPaste()
  local clip = love.system.getClipboardText()
  return clipboard.decode(clip) ~= nil
end

function self.paste()
  if not chart.loaded then return end

  local clip = love.system.getClipboardText()

  local things = clipboard.decode(clip)

  if not things then
    logs.log('Nothing in clipboard')
    return
  end

  self.clearSelection()

  local b = getBeat()
  for _, thing in ipairs(things) do
    thing.beat = thing.beat + b
    chart.placeThing(thing)
    table.insert(self.selection, thing)
  end
  chart.insertHistory(#things .. ' pasted notes')
  logs.log('Pasted ' .. #things .. ' notes')
end

self.setBeat = setBeat

return self