local edit      = require 'src.edit'
local logs      = require 'src.logs'
local config    = require 'src.config'
local conductor = require 'src.conductor'
local xdrv      = require 'lib.xdrv'
local self      = {}

---@class Keybind
---@field idx integer?
---@field ctrl boolean? @ cmd on Mac
---@field shift boolean?
---@field alt boolean?
---@field viewOnly boolean?
---@field writeOnly boolean?
---@field keys love.Scancode[]
---@field name string?
---@field canRepeat boolean?
---@field alwaysUsable boolean?
---@field trigger fun()
---@field release fun()?


self.binds = {}

local num_binds = 0

---@type table<string, Keybind>
local binds = setmetatable({}, {
  __newindex = function(_, k, v)
    if self.binds[k] then
      v.idx = self.binds[k].idx
    else
      num_binds = num_binds + 1
      v.idx = num_binds
    end
    self.binds[k] = v
  end
})

binds.new = {
  name = 'New',
  ctrl = true,
  viewOnly = true,
  keys = { 'n' },
  trigger = function()
    chart.newChart()
  end
}
binds.open = {
  name = 'Open',
  ctrl = true,
  viewOnly = true,
  keys = { 'o' },
  trigger = function()
    chart.openChart()
  end
}
binds.save = {
  name = 'Save as...',
  ctrl = true,
  shift = true,
  keys = { 's' },
  trigger = function()
    chart.saveChart()
  end
}
binds.quicksave = {
  name = 'Save',
  ctrl = true,
  keys = { 's' },
  trigger = function()
    chart.quickSave()
  end
}
binds.undo = {
  name = 'Undo',
  ctrl = true,
  keys = { 'z' },
  trigger = edit.undo,
}
binds.redo = {
  name = 'Redo',
  ctrl = true,
  shift = MACOS,
  keys = MACOS and { 'z' } or { 'y' },
  trigger = edit.redo,
}
binds.selectAll = {
  name = 'Select All',
  ctrl = true,
  keys = { 'a' },
  trigger = edit.selectAll,
}
binds.cut = {
  name = 'Cut',
  ctrl = true,
  keys = { 'x' },
  trigger = edit.cut,
}
binds.copy = {
  name = 'Copy',
  ctrl = true,
  keys = { 'c' },
  trigger = edit.copy,
}
binds.paste = {
  name = 'Paste',
  ctrl = true,
  keys = { 'v' },
  trigger = edit.paste,
}
binds.delete = {
  name = 'Delete',
  keys = { 'delete' },
  trigger = edit.deleteKey,
}
binds.viewBinds = {
  name = 'View keybinds',
  keys = { MACOS and 'f12' or 'f11' },
  alwaysUsable = true,
  trigger = function()
    edit.viewBinds = not edit.viewBinds
  end
}
binds.reload = {
  name = 'Reload',
  ctrl = true,
  keys = { 'r' },
  trigger = function()
    chart.reload()
  end
}
binds.dumpChart = {
  name = 'Dump chart to log',
  ctrl = true,
  keys = { 'l' },
  trigger = function()
    logs.logFile(pretty(chart.chart))
    logs.log('Wrote chart to trackmaker.log')
  end
}
binds.dumpChartClipboard = {
  name = 'Dump chart to clipboard',
  ctrl = true,
  shift = true,
  keys = { 'l' },
  trigger = function()
    love.system.setClipboardText(pretty(chart.chart))
    logs.log('Wrote chart to clipboard')
  end
}
binds.loadChartClipboard = {
  name = 'Load chart from clipboard',
  ctrl = true,
  shift = true,
  keys = { 'o' },
  trigger = function()
    local t = love.system.getClipboardText()
    chart.chart = loadstring('return ' .. t)()
    logs.log('Loaded ' .. #chart.chart .. ' notes from clipboard')
    chart.sort()
  end
}
binds.sortChart = {
  name = 'Sort chart',
  ctrl = true,
  shift = true,
  keys = { 'q' },
  trigger = function()
    chart.sort()
    logs.log('Sorted :thumbsup:')
  end
}
binds.cycleMode = {
  name = 'Cycle mode',
  keys = { 'tab' },
  trigger = function()
    edit.cycleMode()
  end
}
binds.exitWrite = {
  name = 'Exit write mode',
  keys = { 'escape' },
  writeOnly = true,
  trigger = function()
    if edit.viewBinds then
      edit.viewBinds = false
      return
    end
    edit.write = false
  end
}
binds.decreaseVolume = {
  name = 'Decrease volume',
  keys = { 'down' },
  viewOnly = true,
  shift = true,
  trigger = function()
    config.set(math.max(config.config.volume - 0.05, 0), 'volume')
    logs.log('Volume set to ' .. round(config.config.volume * 100) .. '%')
  end,
}
binds.increaseVolume = {
  name = 'Increase volume',
  keys = { 'up' },
  viewOnly = true,
  shift = true,
  trigger = function()
    config.set(math.min(config.config.volume + 0.05, 1), 'volume')
    logs.log('Volume set to ' .. round(config.config.volume * 100) .. '%')
  end,
}
binds.decreaseLeft = {
  name = 'Decrease speed',
  keys = { 'left' },
  viewOnly = true,
  shift = true,
  canRepeat = true,
  trigger = function()
    config.set(math.max(config.config.musicRate - 0.05, 0.1), 'musicRate')
    logs.log('Music speed set to ' .. round(config.config.musicRate * 100) .. '%')
  end,
}
binds.increaseRight = {
  name = 'Increase speed',
  keys = { 'right' },
  viewOnly = true,
  shift = true,
  canRepeat = true,
  trigger = function()
    config.set(math.min(config.config.musicRate + 0.05, 2), 'musicRate')
    logs.log('Music speed set to ' .. round(config.config.musicRate * 100) .. '%')
  end,
}
binds.beatTick = {
  name = 'Beat tick',
  keys = { 'f3' },
  trigger = function()
    config.toggle('beatTick')
    logs.log('Beat tick: ' .. (config.config.beatTick and 'ON' or 'OFF'))
  end,
}
binds.noteTick = {
  name = 'Note tick',
  keys = { 'f4' },
  trigger = function()
    config.toggle('noteTick')
    logs.log('Note tick: ' .. (config.config.noteTick and 'ON' or 'OFF'))
  end,
}
binds.clearSelection = {
  name = 'Clear selection',
  keys = { 'escape' },
  viewOnly = true,
  trigger = function()
    edit.clearSelection()
  end,
}
binds.mines = {
  name = 'Toggle mines',
  keys = { '`' },
  viewOnly = true,
  trigger = function()
    edit.turnToMines()
  end
}
binds.toggle_playback = {
  name = 'Play / Pause music',
  keys = { 'space' },
  trigger = function()
    conductor.toggle()
  end
}
binds.move_down = {
  name = 'Move down',
  keys = { 'down' },
  canRepeat = true,
  trigger = function()
    edit.moveByQuant(-1)
  end
}
binds.move_up = {
  name = 'Move up',
  keys = { 'up' },
  canRepeat = true,
  trigger = function()
    edit.moveByQuant(1)
  end
}
binds.move_down_measure = {
  name = 'Move down measure',
  keys = { 'pagedown' },
  canRepeat = true,
  trigger = function()
    edit.move(-4)
  end
}
binds.move_up_measure = {
  name = 'Move up measure',
  keys = { 'pageup' },
  canRepeat = true,
  trigger = function()
    edit.move(4)
  end
}
binds.decrease_quant = {
  name = 'Decrease beat division',
  keys = { 'left' },
  canRepeat = true,
  trigger = function()
    edit.setQuantIndex(edit.quantIndex - 1)
  end
}
binds.increase_quant = {
  name = 'Increase beat division',
  keys = { 'right' },
  canRepeat = true,
  trigger = function()
    edit.setQuantIndex(edit.quantIndex + 1)
  end
}
binds.place_left_gear = {
  name = 'Place left gear',
  keys = { 'lshift' },
  trigger = function()
    edit.beginGearShift(xdrv.XDRVLane.Left)
  end,
  release = function()
    edit.endGearShift(xdrv.XDRVLane.Left)
  end
}
binds.place_right_gear = {
  name = 'Place right gear',
  keys = { 'rshift' },
  trigger = function()
    edit.beginGearShift(xdrv.XDRVLane.Right)
  end,
  release = function()
    edit.endGearShift(xdrv.XDRVLane.Right)
  end
}
binds.place_column_1 = {
  name = 'Place column 1 note',
  keys = { '1', 'a' },
  trigger = function()
    edit.beginNote(1)
  end,
  release = function()
    edit.endNote(1)
  end
}
binds.place_column_2 = {
  name = 'Place column 2 note',
  keys = { '2', 's' },
  trigger = function()
    edit.beginNote(2)
  end,
  release = function()
    edit.endNote(2)
  end
}
binds.place_column_3 = {
  name = 'Place column 3 note',
  keys = { '3', 'd' },
  trigger = function()
    edit.beginNote(3)
  end,
  release = function()
    edit.endNote(3)
  end
}
binds.place_column_4 = {
  name = 'Place column 4 note',
  keys = { '4', 'l'},
  trigger = function()
    edit.beginNote(4)
  end,
  release = function()
    edit.endNote(4)
  end
}
binds.place_column_5 = {
  name = 'Place column 5 note',
  keys = { '5', ';' },
  trigger = function()
    edit.beginNote(5)
  end,
  release = function()
    edit.endNote(5)
  end
}
binds.place_column_6 = {
  name = 'Place column 6 note',
  keys = { '6', '\'' },
  trigger = function()
    edit.beginNote(6)
  end,
  release = function()
    edit.endNote(6)
  end
}
binds.place_left_drift = {
  name = 'Place left drift',
  keys = { ',' },
  trigger = function()
    edit.placeDrift(xdrv.XDRVDriftDirection.Left)
  end
}
binds.place_right_drift = {
  name = 'Place right drift',
  keys = { '.' },
  trigger = function()
    edit.placeDrift(xdrv.XDRVDriftDirection.Right)
  end
}
binds.place_neutral_drift = {
  name = 'Place neutral drift',
  keys = { '/' },
  trigger = function()
    edit.placeDrift(xdrv.XDRVDriftDirection.Neutral)
  end
}

local function formatKey(key)
  return string.upper(string.sub(key, 1, 1)) .. string.sub(key, 2)
end

---@param bind Keybind
---@param special {ctrl: boolean, shift: boolean, alt: boolean}
---@param key love.KeyConstant
---@param isRepeat boolean
local function check_bind(bind, special, key, code, isRepeat)
  local invalid = not bind.alwaysUsable and (
    (not bind.canRepeat and isRepeat) or
    (bind.viewOnly and edit.write) or
    (bind.writeOnly and not edit.write) or
    (bind.ctrl and not special.ctrl) or
    (bind.shift and not special.shift) or
    (bind.alt and not special.alt) or
    edit.viewBinds
  )
  if invalid then
    return false
  end

  for _, bind_key in ipairs(bind.keys) do
    if bind_key == key or bind_key == code then
      return true
    end
  end
  return false
end

function self.keypressed(key, code, isRepeat)
  local special = {
    ---@diagnostic disable-next-line: param-type-mismatch
    ctrl = love.keyboard.isDown(MACOS and 'lgui' or 'lctrl') or love.keyboard.isDown(MACOS and 'rgui' or 'rctrl'),
    shift = love.keyboard.isDown('lshift') or love.keyboard.isDown('rshift'),
    alt = love.keyboard.isDown('lalt') or love.keyboard.isDown('ralt'),
  }

  local triggeredKeybinds = {}
  for _, bind in pairs(self.binds or {}) do
    if check_bind(bind, special, key, code, isRepeat) then
      table.insert(triggeredKeybinds, bind)
    end
  end

  if #triggeredKeybinds == 0 then return end

  local maxPrio = -1
  local maxBind = nil
  for _, bind in ipairs(triggeredKeybinds) do
    local prio = (bind.ctrl and 1 or 0) + (bind.shift and 2 or 0) + (bind.alt and 4 or 0)
    if prio > maxPrio then
      maxPrio = prio
      maxBind = bind
    end
  end

  if maxBind then maxBind.trigger() end
end

function self.keyreleased(key, code)
  for _, bind in pairs(self.binds) do
    if bind.release then
      for _, bind_key in ipairs(bind.keys) do
        if (bind_key == key or bind_key == code) then
          bind.release()
          break
        end
      end
    end
  end
end

---@param bind Keybind
function self.formatBind(bind)
  local segments = {}
  if bind.ctrl then table.insert(segments, MACOS and '⌘' or 'Ctrl') end
  if bind.shift then table.insert(segments, MACOS and '⇧' or 'Shift') end
  if bind.alt then table.insert(segments, MACOS and '⌥' or 'Alt') end
  -- on macos the order is ⌥⇧⌘ (alt shift ctrl) so reverse the list
  if MACOS then
    local newSegments = {}
    for i = #segments, 1, -1 do
      newSegments[#segments - i + 1] = segments[i]
    end
    segments = newSegments
  end

  local keys = {}
  for _, key in ipairs(bind.keys) do
    table.insert(keys, formatKey(key))
  end
  table.insert(segments, table.concat(keys, ' | '))

  return table.concat(segments, MACOS and '' or '+')
end

return self