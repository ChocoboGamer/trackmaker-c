local xdrv = require 'lib.xdrv'

local MAGIC = 'wizvol'

local self = {}

-- wabung$tB$>▭5+.5▭3+.5▭1+.5◨~4+1.5▭3~.5+1.5▭6~1+2▭3~.5+1▭5~.5
-- this format is completely ancient interface core but that's ok

-- wabung$tB$>▭2+.5▭31&▭6&▭35&▭4&▭3&▭5&▭13&▭5&▭3&▭5&▭3&▭1&◨~4+1.5▭3~.5&▭6~1+2▭3~.5+1▭5~.5
-- wabung$tB$>▭46+.5▭5&▭4&▭2&▭31&▭6&▭35&▭4&▭3&▭5&▭13&▭5&▭3&▭5&▭3&▭1&◨~4+1.5▭3~.5&▭6~1

local SEPERATOR = '$'

local SYMBOL = {
  PLUS = '+',
  PLUS_REPEAT = '&',
  HOLD = '~',
  NOTE = 'o',
  MINE = 'x',
  GEAR_LEFT = 'l',
  GEAR_RIGHT = 'r',
  DRIFT_LEFT = '<',
  DRIFT_RIGHT = '>',
  DRIFT_NEUTRAL = 'v',
}
local SYMBOL_CHAR = '+&~oxlr<>v'

---@param number number
---@return string
local function formatNum(number)
  return string.match(tostring(number), '^0*(.*)$')
end
---@param str string
---@return number?
local function readNum(str)
  return tonumber('0' .. str)
end

---@param chart_events XDRVThing[]
---@return string
function self.encode(chart_events)
  local clip = {}

  local lastGap
  local cur_beat = chart_events[1].beat
  for _, event in ipairs(chart_events) do
    if event.beat > cur_beat then
      local gap = event.beat - cur_beat
      if gap == lastGap then
        table.insert(clip, SYMBOL.PLUS_REPEAT)
      else
        table.insert(clip, SYMBOL.PLUS .. formatNum(gap))
      end
      lastGap = gap
      cur_beat = event.beat
    end

    local str = ''
    if event.note then
      local isMine = event.note.mine
      local isHold = event.note.length ~= nil

      local char = SYMBOL.NOTE
      local col = event.note.column
      local hold = ''

      if isMine then
        char = SYMBOL.MINE
      end
      if isHold then
        hold = SYMBOL.HOLD .. formatNum(event.note.length)
      end

      str = char .. col .. hold
    elseif event.gearShift then
      local char = SYMBOL.GEAR_LEFT
      local hold = SYMBOL.HOLD .. formatNum(event.gearShift.length)

      if event.gearShift.lane == xdrv.XDRVLane.Right then
        char = SYMBOL.GEAR_RIGHT
      end

      str = char .. hold
    elseif event.drift then
      local char = SYMBOL.DRIFT_NEUTRAL
      if event.drift.direction == xdrv.XDRVDriftDirection.Left then
        char = SYMBOL.DRIFT_LEFT
      elseif event.drift.direction == xdrv.XDRVDriftDirection.Right then
        char = SYMBOL.DRIFT_RIGHT
      end
      str = char
    end
    table.insert(clip, str)
  end

  local out = {}

  --MAGIC
  table.insert(out, MAGIC)
  -- chart
  table.insert(out, table.concat(clip, ''))

  return table.concat(out, SEPERATOR)
end

---@param clipboard_str string
---@return XDRVThing[]?
function self.decode(clipboard_str)
  local chart_events = {}

  local chart = string.match(clipboard_str, string.format('^%s%s(.*)$', MAGIC, SEPERATOR))
  if not chart then
    return
  end

  local lastGap
  local cur_beat = 0
  for command in string.gmatch(chart, string.format('[%s][^%s]*', SYMBOL_CHAR, SYMBOL_CHAR)) do
    local type, arg_str = string.match(command, '^(.)(.*)$')
    local arg = readNum(arg_str)


    if type == SYMBOL.PLUS then
      cur_beat = cur_beat + arg
      lastGap = arg
    elseif type == SYMBOL.PLUS_REPEAT then
      cur_beat = cur_beat + lastGap
    elseif type == SYMBOL.HOLD then
      local prev = chart_events[#chart_events]
      if prev then
        if prev.note then
          prev.note.length = arg
        elseif prev.gearShift then
          prev.gearShift.length = arg
        end
      end
    elseif type == SYMBOL.NOTE then
      table.insert(chart_events, { beat = cur_beat, note = { column = arg } })
    elseif type == SYMBOL.MINE then
      table.insert(chart_events, { beat = cur_beat, note = { column = arg, mine = true } })
    elseif type == SYMBOL.GEAR_LEFT then
      table.insert(chart_events, { beat = cur_beat, gearShift = { lane = xdrv.XDRVLane.Left, length = 0 } })
    elseif type == SYMBOL.GEAR_RIGHT then
      table.insert(chart_events, { beat = cur_beat, gearShift = { lane = xdrv.XDRVLane.Right, length = 0 } })
    elseif type == SYMBOL.DRIFT_LEFT then
      table.insert(chart_events, { beat = cur_beat, drift = { direction = xdrv.XDRVDriftDirection.Left } })
    elseif type == SYMBOL.DRIFT_RIGHT then
      table.insert(chart_events, { beat = cur_beat, drift = { direction = xdrv.XDRVDriftDirection.Right } })
    elseif type == SYMBOL.DRIFT_NEUTRAL then
      table.insert(chart_events, { beat = cur_beat, drift = { direction = xdrv.XDRVDriftDirection.Neutral } })
    end
  end

  return chart_events
end

return self