local M = {}

local sort = require 'lib.sort'

local SEGMENT_INCR = 1 -- beats

local function gcd(m, n)
  local iters = 0
  while n ~= 0 do
    iters = iters + 1
    if iters > 9999 then
      print('gcd infloop ', m, n)
      return m
    end
    local q = m
    m = n
    n = q % n
  end
  return m
end

local function lcm(m, n)
  return (m ~= 0 and n ~= 0) and m * n / gcd(m, n) or 0
end

local QUANTS = {
  1,
  1 / 2,
  1 / 3,
  1 / 4,
  1 / 5,
  1 / 6,
  1 / 8,
  1 / 12,
  1 / 16,
  1 / 24,
  1 / 48,
}

local EPSILON = QUANTS[#QUANTS] / 8

local function getQuantIndex(beat)
  for i, quant in ipairs(QUANTS) do
    if math.abs(beat - round(beat / quant) * quant) < EPSILON then
      return i
    end
  end
  return #QUANTS
end

local function getDivision(beat)
  return 1 / QUANTS[getQuantIndex(beat)]
end

---@enum XDRVDifficulty
M.XDRVDifficulty = {
  Beginner = 0,
  Normal = 1,
  Hyper = 2,
  Extreme = 3,
  Overdrive = 4,
}

M.STAGE_BACKGROUNDS = {
  'BackgroundTunnel',
  'BackgroundCity',
  'BackgroundIgnia',
  'BackgroundVivid',
  'BackgroundDesert',
  'BackgroundRush',
}

M.CHART_LEVELSTYLES = {
  'NORMAL',
  'HIDDEN',
  'BANGBANG',
  'COLON_ANGLE_BRACKET',
  'COLON_SQUARE_BRACKET',
  'COLON_THREE',
  'COLON_THREE_C',
  'CUBED',
  'CURRENCY',
  'DOUBLE_MINUS',
  'DOUBLE_PLUS',
  'DOUBLE_QUESTION',
  'ELIPSIS',
  'ELITE_GAMER',
  'EVIL',
  'EXCLAMATION',
  'FREEWAY',
  'HAPPY',
  'IMAGINARY',
  'INTERROBANG',
  'MAYBE',
  'MINUS',
  'PERIOD',
  'PLUS',
  'QUESTION',
  'QUOTES',
  'SAD',
  'SAGE',
  'SQUARE_ROOT',
  'SQUARED',
  'SUPER_HAPPY',
  'MIDDY',
}

---@class XDRVMetadata
---@field musicTitle string @ MUSIC_TITLE
---@field alternateTitle string @ ALTERNATE_TITLE
---@field subtitle string @ SUBTITLE
---@field musicArtist string @ MUSIC_ARTIST
---@field musicCredit string @ MUSIC_CREDIT
---@field musicCreditColor string @ MUSIC_CREDIT_COLOR
---@field musicAudio string @ MUSIC_AUDIO
---@field disableMusicPreview boolean @ DISABLE_MUSIC_PREVIEW
---@field musicPreviewStart number @ MUSIC_PREVIEW_START
---@field musicPreviewLength number @ MUSIC_PREVIEW_LENGTH
---@field musicVolume number @ MUSIC_VOLUME
---@field musicOffset number @ MUSIC_OFFSET
---@field jacketImage string @ JACKET_IMAGE
---@field jacketHeight number @ JACKET_HEIGHT [undocumented, prolly by mistake]
---@field jacketIllustrator string @ JACKET_ILLUSTRATOR
---@field chartAuthor string @ CHART_AUTHOR
---@field chartAuthors string[] @ CHART_AUTHORS
---@field modAuthor string @ MOD_AUTHOR
---@field modAuthors string[] @ MOD_AUTHORS
---@field chartBoss boolean @ CHART_BOSS
---@field chartDifficulty XDRVDifficulty @ CHART_DIFFICULTY
---@field chartLevel number @ CHART_LEVEL
---@field chartUnlock string @ CHART_UNLOCK
---@field chartDisplayBPM number @ CHART_DISPLAY_BPM
---@field chartBPM number @ CHART_BPM
---@field isFlashTrack boolean @ FLASH_TRACK
---@field isKeyboardOnly boolean @ KEYBOARD_ONLY
---@field isOriginal boolean @ ORIGINAL
---@field modfilePath string @ MODFILE_PATH
---@field rpcHidden boolean @ RPC_HIDDEN
---@field disableLeaderboardUploading boolean @ DISABLE_LEADERBOARD_UPLOADING
---@field stageBackground string @ STAGE_BACKGROUND
---@field _discardedTags table<string, string> @ for unrecognized or invalid tags

---@alias XDRVMetadataValueType 'string' | 'stringArray' | 'float' | 'int' | 'bool' | 'difficulty' | 'chartLevelStyle'

-- until lua-lsp adds a keyof<> this is the best we're getting
-- probably susceptible to missing a key either in the type def or in this table
-- still better than the other solution of having to sync across 3 places!
---@type { [1]: string, [2]: string, [3]: XDRVMetadataValueType, default: any?, singular: string?}[]
local metadataTags = {
  { 'MUSIC_TITLE',                   'musicTitle',                  'string' },
  { 'ALTERNATE_TITLE',               'alternateTitle',              'string' },
  { 'SUBTITLE',                      'subtitle',                    'string' },
  { 'MUSIC_CREDIT',                  'musicCredit',                 'string' },
  { 'MUSIC_SORUCE',                  'musicSource',                 'string' },
  { 'MUSIC_COPYRIGHT',               'musicCopyright',              'string' },
  { 'MUSIC_CREDIT_COLOR',            'musicCreditColor',            'string' },
  { 'MUSIC_ARTIST',                  'musicArtist',                 'string' },
  { 'MUSIC_AUDIO',                   'musicAudio',                  'string' },
  { 'DISABLE_MUSIC_PREVIEW',         'disableMusicPreview',         'bool',        default = false },
  { 'MUSIC_PREVIEW_START',           'musicPreviewStart',           'float',       default = 0 },
  { 'MUSIC_PREVIEW_LENGTH',          'musicPreviewLength',          'float',       default = 10 },
  { 'MUSIC_VOLUME',                  'musicVolume',                 'float',       default = 1 },
  { 'MUSIC_OFFSET',                  'musicOffset',                 'float',       default = 0 },
  { 'JACKET_IMAGE',                  'jacketImage',                 'string' },
  { 'JACKET_ILLUSTRATOR',            'jacketIllustrator',           'string' },
  { 'JACKET_HEIGHT',                 'jacketHeight',                'float',       default = 0.345 },
  { 'CHART_AUTHORS',                 'chartAuthors',                'stringArray', singular = 'CHART_AUTHOR' },
  { 'MOD_AUTHORS',                   'modAuthors',                  'stringArray', singular = 'MOD_AUTHOR' },
  { 'CHART_BOSS',                    'chartBoss',                   'bool',        default = false },
  { 'CHART_DIFFICULTY',              'chartDifficulty',             'difficulty',  default = M.XDRVDifficulty.Normal },
  { 'CHART_LEVEL',                   'chartLevel',                  'int',         default = 0 },
  { 'CHART_LEVEL_STYLE',             'chartLevelStyle',             'string',      default = 'NORMAL' },
  { 'CHART_UNLOCK',                  'chartUnlock',                 'string' },
  { 'CHART_DISPLAY_BPM',             'chartDisplayBPM',             'int',         default = 120 },
  { 'CHART_BPM',                     'chartBPM',                    'float',       default = 120 },
  { 'FLASH_TRACK',                   'isFlashTrack',                'bool',        default = false },
  { 'KEYBOARD_ONLY',                 'isKeyboardOnly',              'bool',        default = false },
  { 'ORIGINAL',                      'isOriginal',                  'bool',        default = false },
  { 'MODFILE_PATH',                  'modfilePath',                 'string' },
  { 'RPC_HIDDEN',                    'rpcHidden',                   'bool',        default = true },
  { 'DISABLE_LEADERBOARD_UPLOADING', 'disableLeaderboardUploading', 'bool',        default = true },
  { 'STAGE_BACKGROUND',              'stageBackground',             'string',      default = 'BackgroundTunnel' },
}

---@type table<XDRVMetadataValueType, any>
local defaultValues = {
  string = '',
  stringArray = {},
  float = 0,
  int = 0,
  bool = false,
  difficulty = M.XDRVDifficulty.Beginner,
}

M.defaultMetadata = {}
M.defaultMetadata._discardedTags = {}
for _, tag in ipairs(metadataTags) do
  if tag.default then
    M.defaultMetadata[tag[2]] = tag.default
  else
    M.defaultMetadata[tag[2]] = defaultValues[tag[3]]
  end
end

local function trim(s)
  return string.match(s, '^%s*(.*%S)') or ''
end
local function round(n)
  return n >= 0 and math.floor(n + 0.5) or math.ceil(n - 0.5)
end

---@type table<XDRVMetadataValueType, fun(value: string?): any>
local metadataValueParsers = {}

function metadataValueParsers.string(s)
  if type(s) ~= 'string' then return '' end
  return s
end

function metadataValueParsers.stringArray(s)
  if type(s) ~= 'string' then return {} end

  local strs = {}
  for str in string.gmatch(s, '([^,]+)') do
    table.insert(strs, trim(str))
  end
  return strs
end

function metadataValueParsers.float(s)
  return tonumber(s) or -1
end

function metadataValueParsers.int(s)
  return round(metadataValueParsers.float(s))
end

function metadataValueParsers.bool(s)
  return s == 'TRUE'
end

function metadataValueParsers.difficulty(s)
  if s == 'BEGINNER' then return M.XDRVDifficulty.Beginner end
  if s == 'NORMAL' then return M.XDRVDifficulty.Normal end
  if s == 'HYPER' then return M.XDRVDifficulty.Hyper end
  if s == 'EXTREME' then return M.XDRVDifficulty.Extreme end
  if s == 'OVERDRIVE' then return M.XDRVDifficulty.Overdrive end

  return M.XDRVDifficulty.Beginner
end

---@type table<XDRVMetadataValueType, fun(value: any): string>
local metadataValueSerializers = {}

function metadataValueSerializers.string(s)
  return s
end

function metadataValueSerializers.stringArray(s)
  return table.concat(s, ', ')
end

function metadataValueSerializers.float(n)
  return tostring(n)
end

function metadataValueSerializers.int(n)
  return tostring(round(n))
end

function metadataValueSerializers.bool(b)
  return b and 'TRUE' or 'FALSE'
end

function metadataValueSerializers.difficulty(d)
  if d == M.XDRVDifficulty.Beginner then return 'BEGINNER' end
  if d == M.XDRVDifficulty.Normal then return 'NORMAL' end
  if d == M.XDRVDifficulty.Hyper then return 'HYPER' end
  if d == M.XDRVDifficulty.Extreme then return 'EXTREME' end
  if d == M.XDRVDifficulty.Overdrive then return 'OVERDRIVE' end
  return 'BEGINNER'
end

M.formatDifficulty = metadataValueSerializers.difficulty

---@param metadata XDRVMetadata
---@return ({[1]: string, [2]: string})[]
local function serializeMetadataValues(metadata)
  local data = {}

  for _, tag in ipairs(metadataTags) do
    local xdrv_name = tag[1]
    local trmk_name = tag[2]
    local what = tag[3]

    local v
    if metadata[trmk_name] then
      if tag.singular and #metadata[trmk_name] <= 1 then
        xdrv_name = tag.singular
      end

      v = metadataValueSerializers[what](metadata[trmk_name])
    else
      v = metadataValueSerializers[what](tag.default or defaultValues[what])
    end

    table.insert(data, { xdrv_name, v })
  end

  for tag, value in pairs(metadata._discardedTags) do
    table.insert(data, { tag, value })
  end

  return data
end

---@param t {key: string, value: any}[]
---@return XDRVMetadata
local function parseMetadataValues(t)
  local metadata = {}
  metadata._discardedTags = {}

  for _, line in ipairs(t) do
    local foundMatch = false
    for _, tag in ipairs(metadataTags) do
      local xdrv_name = tag[1]
      local trmk_name = tag[2]
      local type = tag[3]

      if line.key == xdrv_name or line.key == tag.singular then
        metadata[trmk_name] = metadataValueParsers[type](line.value)
        foundMatch = true
        break
      end
    end

    if not foundMatch then
      metadata._discardedTags[line.key] = line.value
    end
  end

  for _, tag in ipairs(metadataTags) do
    local trmk_name = tag[2]
    if not metadata[trmk_name] then
      local type = tag[3]
      metadata[trmk_name] = tag.default or defaultValues[type]
    end
  end

  return metadata
end

function M.formatDifficultyShort(d)
  if d == M.XDRVDifficulty.Beginner then return 'BG' end
  if d == M.XDRVDifficulty.Normal then return 'NM' end
  if d == M.XDRVDifficulty.Hyper then return 'HY' end
  if d == M.XDRVDifficulty.Extreme then return 'EX' end
  if d == M.XDRVDifficulty.Overdrive then return 'OV' end
  return 'NM'
end

local function parseLane(str)
  if str == 'left' then return M.XDRVLane.Left end
  if str == 'right' then return M.XDRVLane.Right end
  return M.XDRVLane.None
end
local function formatLane(lane)
  if lane == M.XDRVLane.Left then return 'left' end
  if lane == M.XDRVLane.Right then return 'right' end
end

---@enum XDRVLane
M.XDRVLane = {
  None = -1,
  Left = 1,
  Right = 2,
}

---@enum XDRVDriftDirection
M.XDRVDriftDirection = {
  None = -1,
  Left = 1,
  Right = 2,
  Neutral = 3,
}

---@alias XDRVNoteColumn 1 | 2 | 3 | 4 | 5 | 6

---@alias XDRVNote { beat: number, note: { column: XDRVNoteColumn, length: number?, mine: boolean? } }
---@alias XDRVHoldStart { beat: number, holdStart: { column: XDRVNoteColumn } }
---@alias XDRVHoldEnd { beat: number, holdEnd: { column: XDRVNoteColumn } }
---@alias XDRVGearShift { beat: number, gearShift: { lane: XDRVLane, length: number } }
---@alias XDRVGearShiftStart { beat: number, gearShiftStart: { lane: XDRVLane } }
---@alias XDRVGearShiftEnd { beat: number, gearShiftEnd: { lane: XDRVLane } }
---@alias XDRVDrift { beat: number, drift: { direction: XDRVDriftDirection } }
---@alias XDRVBPMChange { beat: number, bpm: number }
---@alias XDRVWarp { beat: number, warp: number }
---@alias XDRVStop { beat: number, stop: number }
---@alias XDRVStopSeconds { beat: number, stopSeconds: number }
---@alias XDRVScroll { beat: number, scroll: number }
---@alias XDRVTimeSignature { beat: number, timeSignature: { [1]: number, [2]: number } }
---@alias XDRVComboTicks { beat: number, comboTicks: number }
---@alias XDRVLabel { beat: number, label: string }
---@alias XDRVFake { beat: number, fake: { [1]: number, [2]: XDRVNoteColumn? } }
---@alias XDRVSceneEvent { beat: number, event: { name: string, args: string[] } }
---@alias XDRVCheckpoint { beat: number, checkpoint: string }
---@alias XDRVMeasureLine { beat: number, measureLine: XDRVLane }
---@alias XDRVThing XDRVNote | XDRVHoldStart | XDRVHoldEnd | XDRVGearShift | XDRVGearShiftStart | XDRVGearShiftEnd | XDRVDrift | XDRVBPMChange | XDRVWarp | XDRVStop | XDRVStopSeconds | XDRVScroll | XDRVTimeSignature | XDRVComboTicks | XDRVLabel | XDRVFake | XDRVSceneEvent | XDRVCheckpoint | XDRVMeasureLine

local raw_parsers = {
  [0] = {
    MEASURE_LINE = function(beat, arg1)
      return {
        beat = beat,
        measureLine = parseLane(arg1),
      }
    end,
  },
  [1] = {
    BPM = function(beat, arg1)
      return {
        beat = beat,
        bpm = tonumber(arg1),
      }
    end,

    WARP = function(beat, arg1)
      return {
        beat = beat,
        warp = tonumber(arg1),
      }
    end,

    STOP = function(beat, arg1)
      return {
        beat = beat,
        stop = tonumber(arg1),
      }
    end,

    STOP_SECONDS = function(beat, arg1)
      return {
        beat = beat,
        stopSeconds = tonumber(arg1),
      }
    end,

    SCROLL = function(beat, arg1)
      return {
        beat = beat,
        scroll = tonumber(arg1),
      }
    end,

    COMBO_TICKS = function(beat, arg1)
      return {
        beat = beat,
        comboTicks = tonumber(arg1),
      }
    end,

    LABEL = function(beat, arg1)
      return {
        beat = beat,
        label = arg1,
      }
    end,

    FAKE = function(beat, arg1, arg2)
      return {
        beat = beat,
        fake = { tonumber(arg1), arg2 and tonumber(arg2) },
      }
    end,

    EVENT = function(beat, arg1, ...)
      return {
        beat = beat,
        event = { name = arg1, args = { ... } },
      }
    end,

    CHECKPOINT = function(beat, arg1)
      return {
        beat = beat,
        checkpoint = arg1,
      }
    end,
  },
  [2] = {
    TIME_SIGNATURE = function(beat, arg1, arg2)
      return {
        beat = beat,
        timeSignature = { tonumber(arg1), tonumber(arg2) },
      }
    end,
  },
}

---@return XDRVThing?
local function parseTimingSegment(beat, s)
  local key, value = string.match(s, '^#?([^=]+)=?(.*)$')

  local args = {}
  for arg in string.gmatch(value, '[^,]+') do
    table.insert(args, arg)
  end

  for min_args = 0, 2 do
    local parser = raw_parsers[min_args][key]
    if parser then
      return parser(beat, unpack(args))
    end
  end
  return nil
end

---@param chart_events XDRVThing[]
---@return XDRVThing[]
function M.addHoldEnds(chart_events)
  local newEvents = {}

  for _, event in ipairs(chart_events) do
    if event.note and event.note.length then
      if event.note.length == 0 then -- 0 length hold outputs a tap note
        table.insert(newEvents, {
          beat = event.beat,
          note = { column = event.note.column, mine = event.note.mine }
        })
      else
        table.insert(newEvents, {
          beat = event.beat,
          holdStart = { column = event.note.column }
        })
        table.insert(newEvents, {
          beat = event.beat + event.note.length,
          holdEnd = { column = event.note.column }
        })
      end
    elseif event.gearShift then
      if event.gearShift.length == 0 then -- 0 length gear outputs a gearhead
        table.insert(newEvents, {
          beat = event.beat,
          gearShiftStart = { lane = event.gearShift.lane }
        })
      else
        table.insert(newEvents, {
          beat = event.beat,
          gearShiftStart = { lane = event.gearShift.lane }
        })
        table.insert(newEvents, {
          beat = event.beat + event.gearShift.length,
          gearShiftEnd = { lane = event.gearShift.lane }
        })
      end
    else
      table.insert(newEvents, event)
    end
  end

  -- event lists should be sorted and this function doesn't product a sorted event table
  return sort.insertion_sort(newEvents, function(a, b) return a.beat < b.beat end)
end

---@param chart_events XDRVThing[]
---@return XDRVThing[]
function M.collapseHoldEnds(chart_events)
  local newEvents = {}

  local hold_info = {}
  local gear_info = {}
  local function increment_idx(beat)
    for _, info in pairs(hold_info) do
      if info.obj.beat >= beat then
        info.idx = info.idx + 1
      end
    end
    for _, info in pairs(gear_info) do
      if info.obj.beat >= beat then
        info.idx = info.idx + 1
      end
    end
  end

  for _, event in ipairs(chart_events) do
    if event.holdStart then
      local col = event.holdStart.column

      local info = hold_info[col]
      if info and not info.used then
        table.insert(newEvents, info.idx, {
          beat = info.obj.beat,
          note = {
            column = col,
            mine = false
          },
        })
        increment_idx(info.obj.beat)
      end

      hold_info[col] = {
        obj = event,
        idx = #newEvents + 1,
        used = false,
      }
    elseif event.holdEnd then
      local col = event.holdEnd.column

      local info = hold_info[col]
      if info then
        table.insert(newEvents, info.idx, {
          beat = info.obj.beat,
          note = {
            column = col,
            length = event.beat - info.obj.beat,
            mine = false,
          }
        })
        increment_idx(info.obj.beat)

        info.used = true
      end
    elseif event.gearShiftStart then
      local lane = event.gearShiftStart.lane

      local info = gear_info[lane]
      if info and not info.used then
        table.insert(newEvents, info.idx, {
          beat = info.obj.beat,
          gearShift = {
            lane = lane,
            length = 0,
          },
        })
        increment_idx(info.obj.beat)
      end

      gear_info[lane] = {
        obj = event,
        idx = #newEvents + 1,
        used = false,
      }
    elseif event.gearShiftEnd then
      local lane = event.gearShiftEnd.lane

      local info = gear_info[lane]
      if info then
        table.insert(newEvents, info.idx, {
          beat = info.obj.beat,
          gearShift = {
            lane = lane,
            length = event.beat - info.obj.beat,
          }
        })
        increment_idx(info.obj.beat)

        info.used = true
      end
    else
      table.insert(newEvents, event)
    end
  end

  return newEvents
end

---@param thing XDRVThing
local function noteToType(thing)
  if not thing then return '0' end
  if thing.note and thing.note.mine then return 'M' end
  if thing.note then return '1' end
  if thing.holdStart then return '2' end
  if thing.holdEnd then return '4' end
  return '0'
end
---@param c table<number, XDRVThing>
local function formatNotesCol(c)
  return
      noteToType(c[1]) ..
      noteToType(c[2]) ..
      noteToType(c[3]) .. '-' ..
      noteToType(c[4]) ..
      noteToType(c[5]) ..
      noteToType(c[6])
end
---@param thing XDRVThing
local function gearToType(thing)
  if not thing then return '0' end
  if thing.gearShiftStart then return '1' end
  if thing.gearShiftEnd then return '2' end
  return '0'
end
---@param g table<XDRVLane, XDRVThing>
local function formatGears(g)
  return gearToType(g[M.XDRVLane.Left]) .. gearToType(g[M.XDRVLane.Right])
end
---@param s XDRVDriftDirection?
local function formatDrift(s)
  if s == M.XDRVDriftDirection.Left then
    return '1'
  end
  if s == M.XDRVDriftDirection.Right then
    return '2'
  end
  if s == M.XDRVDriftDirection.Neutral then
    return '3'
  end
  return '0'
end
local function noteEvent(beat, s, c)
  if s == '1' then
    return { beat = beat, note = { column = c } }
  end
  if s == '2' then
    return { beat = beat, holdStart = { column = c } }
  end
  if s == '4' then
    return { beat = beat, holdEnd = { column = c } }
  end
  if s == 'M' then
    return { beat = beat, note = { column = c, mine = true } }
  end
  return nil
end
local function gearShiftEvent(beat, s, lane)
  if s == '1' then
    return { beat = beat, gearShiftStart = { lane = lane } }
  end
  if s == '2' then
    return { beat = beat, gearShiftEnd = { lane = lane } }
  end
  return nil
end
local function driftEvent(beat, s)
  if s == '1' then
    return { beat = beat, drift = { direction = M.XDRVDriftDirection.Left } }
  end
  if s == '2' then
    return { beat = beat, drift = { direction = M.XDRVDriftDirection.Right } }
  end
  if s == '3' then
    return { beat = beat, drift = { direction = M.XDRVDriftDirection.Neutral } }
  end
  return nil
end

---@param things XDRVThing[]
local function serializeChart(things)
  things = M.addHoldEnds(things)

  local segments = {}

  local b = 0
  local thingIdx = 1
  local iter = 0
  while true do
    iter = iter + 1
    if iter > 99999 then
      print('Preventing infinite loop!!! backup and run before everything explodes')
      break
    end
    if thingIdx > #things then break end

    ---@type XDRVThing[]
    local segment = {}
    local add = 0
    for i = thingIdx, #things do
      local thing = things[i]
      if thing.beat >= (b + SEGMENT_INCR - EPSILON) then
        break
      end
      add = add + 1
      if thing.beat >= (b - EPSILON) then
        table.insert(segment, thing)
      end
    end
    thingIdx = thingIdx + add

    local rowsN = 1
    for _, thing in ipairs(segment) do
      if thing.beat >= (b - EPSILON) then
        rowsN = lcm(rowsN, getDivision(thing.beat))
      end
    end
    rowsN = math.min(rowsN, 48) -- the game will only parse up to 48 rows per beat
    --sprint('-> ', #segment, rowsN)

    local segmentStr = {}

    --print(#segment .. ' in segment')

    for row = 1, rowsN do
      local offset = (row - 1) / rowsN

      local cols = {}
      local gears = {}
      local drift = nil

      for i, thing in ipairs(segment) do
        if math.abs(thing.beat - (b + offset)) < EPSILON then
          if thing.note or thing.holdStart or thing.holdEnd then
            local note = thing.note or thing.holdStart or thing.holdEnd
            cols[note.column] = thing
          elseif thing.gearShiftStart or thing.gearShiftEnd then
            local gear = thing.gearShiftStart or thing.gearShiftEnd
            gears[gear.lane] = thing
          elseif thing.drift then
            drift = thing.drift.direction
          elseif thing.bpm then
            table.insert(segmentStr, '#BPM=' .. thing.bpm)
          elseif thing.warp then
            table.insert(segmentStr, '#WARP=' .. thing.warp)
          elseif thing.stop then
            table.insert(segmentStr, '#STOP=' .. thing.stop)
          elseif thing.stopSeconds then
            table.insert(segmentStr, '#STOP_SECONDS=' .. thing.stopSeconds)
          elseif thing.scroll then
            table.insert(segmentStr, '#SCROLL=' .. thing.scroll)
          elseif thing.timeSignature then
            table.insert(segmentStr, '#TIME_SIGNATURE=' .. thing.timeSignature[1] .. ',' .. thing.timeSignature[2])
          elseif thing.comboTicks then
            table.insert(segmentStr, '#COMBO_TICKS=' .. thing.comboTicks)
          elseif thing.label then
            table.insert(segmentStr, '#LABEL=' .. thing.label)
          elseif thing.fake then
            table.insert(segmentStr, '#FAKE=' .. thing.fake[1] .. (thing.fake[2] and (',' .. thing.fake[2]) or ''))
          elseif thing.event then
            table.insert(segmentStr, '#EVENT=' .. thing.event.name .. ',' .. table.concat(thing.event.args, ','))
          elseif thing.checkpoint then
            table.insert(segmentStr, '#CHECKPOINT=' .. thing.checkpoint)
          elseif thing.measureLine then
            if thing.measureLine == -1 then
              table.insert(segmentStr, '#MEASURE_LINE')
            else
              table.insert(segmentStr, '#MEASURE_LINE=' .. formatLane(thing.measureLine))
            end
          end
        end
      end

      table.insert(segmentStr, formatNotesCol(cols) .. '|' .. formatGears(gears) .. '|' .. formatDrift(drift))
    end

    --print(table.concat(segmentStr, '\n'))

    table.insert(segments, table.concat(segmentStr, '\n'))

    b = b + SEGMENT_INCR
  end

  return '--\n' .. table.concat(segments, '\n--\n') .. '\n--'
end

---@param m XDRVMetadata
local function serializeMetadata(m)
  local data = serializeMetadataValues(m)

  local lines = {}
  for _, pair in pairs(data) do
    table.insert(lines, pair[1] .. '=' .. pair[2])
  end

  return table.concat(lines, '\n')
end

function M.serialize(chart)
  return serializeMetadata(chart.metadata) .. '\n' .. serializeChart(chart.chart)
end

---@return XDRVThing[]
local function deserializeChart(str)
  local things = {}

  local parsePos = 1

  local b = 0

  while true do
    local pos, off = string.find(str, '\r?\n--\r?\n', parsePos)

    if not pos then pos = #str + 3 end

    local segment = string.sub(str, parsePos, pos - 3)

    local rows = {}
    local buffer = {}

    for line in string.gmatch(segment, '[^\r\n]+') do
      local isEvent = string.sub(line, 1, 1) == '#'
      if string.len(line) ~= 0 and line ~= '--' and string.sub(line, 1, 2) ~= '//' then
        table.insert(buffer, line)
        if not isEvent then
          table.insert(rows, buffer)
          buffer = {}
        end
      end
    end

    for rowI, row in ipairs(rows) do
      local div = (rowI - 1) / #rows
      local b = b + div
      for n = 1, #row - 1 do
        local seg = row[n]
        local parsed = parseTimingSegment(b, seg)
        if parsed then
          table.insert(things, parsed)
        end
      end
      local noterow = row[#row]
      local c1, c2, c3, c4, c5, c6, l, r, d = string.match(noterow,
        '([%dM])([%dM])([%dM])%-([%dM])([%dM])([%dM])|([%dM])([%dM])|([%dM])')
      if c1 then
        for column, s in ipairs({ c1, c2, c3, c4, c5, c6 }) do
          local ev = noteEvent(b, s, column)
          if ev then table.insert(things, ev) end
        end
        for lane, gear in ipairs({ l, r }) do
          local ev = gearShiftEvent(b, gear, lane)
          if ev then table.insert(things, ev) end
        end
        local ev = driftEvent(b, d)
        if ev then table.insert(things, ev) end
      end
    end

    if off then
      parsePos = off + 1
      b = b + SEGMENT_INCR
    else
      break
    end
  end

  return M.collapseHoldEnds(things)
end

---@param m table<string, string>
---@return XDRVMetadata
local function makeMetadata(m)
  return parseMetadataValues(m)
end

local function deserializeMetadata(str)
  local metadata = {}

  for line in string.gmatch(str, '[^\r\n]+') do
    if string.len(line) ~= 0 and string.sub(line, 1, 2) ~= '//' then
      local eq = string.find(line, '=')
      if eq then
        local key = string.sub(line, 1, eq - 1)
        local value = string.sub(line, eq + 1)

        table.insert(metadata, { key = key, value = value })
      end
    end
  end

  return makeMetadata(metadata)
end

---@alias XDRVChart { metadata: XDRVMetadata, chart: XDRVThing[] }

---@return XDRVChart
function M.deserialize(str)
  local chartStart = string.find(str, '\r?\n--\r?\n')
  if not chartStart then
    return {
      metadata = deserializeMetadata(str)
    }
  end

  local meta = string.sub(str, 1, chartStart - 1)
  local chart = string.sub(str, chartStart + 1)

  return {
    metadata = deserializeMetadata(meta),
    chart = deserializeChart(chart)
  }
end

return M