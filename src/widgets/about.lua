local colors = require 'src.colors'

---@class AboutWidget : Widget
local AboutWidget = Widget:extend()

local jillo = love.graphics.newImage('assets/sprites/jillo.png')
local chegg = love.graphics.newImage('assets/sprites/chegg.png')
local SPRITE_SCALE = 0.6
local WOBBLE_DURATION = 0.4

local function outSine(x) return math.sin(x * (math.pi * 0.5)) end

function AboutWidget:new(x, y)
  AboutWidget.super.new(self, x, y)
  self.width = 250
  self.height = 255

  self.lastJilloClick = 0
  self.lastCheggClick = 0
  self.title = 'About'
end

function AboutWidget:click(x, y, button)
  local jy = 128
  if
      x > self.width / 3 - jillo:getWidth() / 2 * SPRITE_SCALE and
      x < self.width / 3 + jillo:getWidth() / 2 * SPRITE_SCALE and
      y > jy - jillo:getHeight() / 2 * SPRITE_SCALE and
      y < jy + jillo:getHeight() / 2 * SPRITE_SCALE
  then
    self.lastJilloClick = love.timer.getTime()
  end

  if
      x > (self.width / 3 * 2) - chegg:getWidth() / 2 * SPRITE_SCALE and
      x < (self.width / 3 * 2) + chegg:getWidth() / 2 * SPRITE_SCALE and
      y > jy - chegg:getHeight() / 2 * SPRITE_SCALE and
      y < jy + chegg:getHeight() / 2 * SPRITE_SCALE
  then
    self.lastCheggClick = love.timer.getTime()
  end
end

function AboutWidget:draw()
  love.graphics.setColor(colors.background:unpack())
  love.graphics.rectangle('fill', 0, 0, self.width, self.height)

  local t = love.timer.getTime()
  local jillo_wobble = outSine(math.max(math.min((WOBBLE_DURATION - (t - self.lastJilloClick)) / WOBBLE_DURATION, 1), 0)) * 0.25
  local chegg_wobble = outSine(math.max(math.min((WOBBLE_DURATION - (t - self.lastCheggClick)) / WOBBLE_DURATION, 1), 0)) * 0.25

  local jsx, jsy = SPRITE_SCALE + math.cos(t * 11) * jillo_wobble, SPRITE_SCALE + math.sin(t * 11) * jillo_wobble
  local csx, csy = SPRITE_SCALE + math.cos(t * 11) * chegg_wobble, SPRITE_SCALE + math.sin(t * 11) * chegg_wobble

  local offset = 8

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(fonts.inter_16)
  love.graphics.printf({ { colors.text:unpack() }, release.title, { colors.textTertiary:unpack() }, ' v' ..
  release.version }, 0, offset, self.width, 'center')
  love.graphics.setColor(colors.textSecondary:unpack())
  love.graphics.setFont(fonts.inter_12)
  love.graphics.printf('A GUI chart editor for EX-XDRiVER', 0, offset + 22, self.width, 'center')
  love.graphics.printf('by oatmealine', 0, offset + 40, self.width, 'center')
  love.graphics.printf('modified by Chegg', 0, offset + 58, self.width, 'center')
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(jillo, self.width / 3, offset + 40 + 85, 0, jsx, jsy, jillo:getWidth() / 2, jillo:getHeight() / 2)
  love.graphics.draw(chegg, self.width / 3 * 2, offset + 40 + 85, 0, csx,csy, chegg:getWidth() / 2, chegg:getHeight() / 2)
  love.graphics.setColor(colors.textSecondary:unpack())
  love.graphics.printf(
    'Licensed under the zlib license\nCopyright © 2024-2026\nJade "oatmealine" Monoids\nSee license.txt for more information',
    0, offset + 180, self.width, 'center')
end

return AboutWidget