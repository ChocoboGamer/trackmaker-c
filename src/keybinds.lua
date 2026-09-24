local edit      = require 'src.edit'
local logs      = require 'src.logs'
local config    = require 'src.config'
local conductor = require 'src.conductor'
local self      = {}

---@class Keybind
---@field idx integer?
---@field ctrl boolean? @ cmd on Mac
---@field shift boolean?
---@field alt boolean?
---@field viewOnly boolean?
---@field writeOnly boolean?
---@field keys love.Scancode[]?
---@field keyCodes love.KeyConstant[]?
---@field name string?
---@field canRepeat boolean?
---@field alwaysUsable boolean?
---@field trigger fun()?


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
  keyCodes = { 'z' },
  trigger = edit.undo,
}
binds.redo = {
  name = 'Redo',
  ctrl = true,
  shift = MACOS,
  keyCodes = MACOS and { 'z' } or { 'y' },
  trigger = edit.redo,
}
binds.selectAll = {
  name = 'Select All',
  ctrl = true,
  keyCodes = { 'a' },
  trigger = edit.selectAll,
}
binds.cut = {
  name = 'Cut',
  ctrl = true,
  keyCodes = { 'x' },
  trigger = edit.cut,
}
binds.copy = {
  name = 'Copy',
  ctrl = true,
  keyCodes = { 'c' },
  trigger = edit.copy,
}
binds.paste = {
  name = 'Paste',
  ctrl = true,
  keyCodes = { 'v' },
  trigger = edit.paste,
}
binds.delete = {
  name = 'Delete',
  keyCodes = { 'delete' },
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
  name = 'Sort chart (should fix jank)',
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

local function formatKey(key)
  return string.upper(string.sub(key, 1, 1)) .. string.sub(key, 2)
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

  for _, key in ipairs(bind.keys or {}) do
    table.insert(segments, formatKey(key))
  end
  for _, key in ipairs(bind.keyCodes or {}) do
    table.insert(segments, formatKey(key))
  end
  return table.concat(segments, MACOS and '' or '+')
end

return self