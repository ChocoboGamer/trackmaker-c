local conductor = require 'src.conductor'
local ContextWidget = require 'src.widgets.context'
local config        = require 'src.config'

---@class CatjamWidget : Widget
local CatjamWidget = Widget:extend()

local function loadSprites(base, frames)
  local t = {}
  for i = 0, frames - 1 do
    table.insert(t, love.graphics.newImage(base .. lpad(tostring(i), 2, '0') .. '.png'))
  end
  return t
end

local JAMMERS = {
  {
    name = 'CatJAM',
    frames = loadSprites('assets/sprites/jammers/catjam', 79),
    speed = 6.5,
    width = 128,
    height = 128,
    offset = 0.5,
    pingpong = true,
  },
  {
    name = 'Osaka',
    frames = loadSprites('assets/sprites/jammers/osaka', 12),
    speed = 2,
    offset = -0.07,
    width = 115,
    height = 128,
    pingpong = false,
  },
  {
    name = 'Chegg',
    frames = loadSprites('assets/sprites/jammers/chegg', 8),
    speed = 4,
    offset = 0,
    width = 192,
    height = 192,
    pingpong = false,
  }
}

function CatjamWidget:new(x, y)
  CatjamWidget.super.new(self, x, y)
  self.dragAnywhere = true
  self.hasWindowDecorations = false
  self.resizable = false

  self.jammer = JAMMERS[config.config.catjam]
end

function CatjamWidget:click(x, y, button)
  if button ~= 2 then return end

  local entries = {}

  for i, jam in ipairs(JAMMERS) do
    table.insert(entries,
      { jam.name, function() self.jammer = jam config.set(i, 'catjam') end, toggle = true, value = self.jammer.name == jam.name })
  end

  table.insert(entries, {})
  table.insert(entries, { 'Close', function() self.delete = true end })

  openWidget(ContextWidget(self.x + x, self.y + y, entries))
end

local function pingpong(x)
  return math.abs(x % 2 - 1)
end

function CatjamWidget:draw()
  local b = conductor.beat

  local jam = self.jammer

  self.width = jam.width
  self.height = jam.height

  local a = b / jam.speed + jam.offset
  if jam.pingpong then a = 1 - pingpong(a) end
  a = a % 1
  local f = math.max(math.min(math.floor(1 + a * #jam.frames), #jam.frames), 1)
  local frame = jam.frames[f]

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(frame)
end

return CatjamWidget