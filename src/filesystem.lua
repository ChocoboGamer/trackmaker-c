local self             = {}

local nfd              = require 'lib.nfd_bind'
local threads          = require 'src.threads'
local config           = require 'src.config'

local last_opened_path = nil

-- most of this stolen from loenn - thank you for figuring this out!
-- https://github.com/CelestialCartographers/Loenn/blob/340e1af719ade1ba0c8682141c9f50c3f95ee783/src/utils/filesystem.lua

function self.supportWindowsInThreads()
  if config.config.noMultithreading then return false end
  return not MACOS
end

function self.getDirSeparator()
  return WINDOWS and '\\' or '/'
end

-- Crashes on Windows if using / as path separator
local function fixNFDPath(path)
  if not path then
    return
  end

  if WINDOWS then
    return string.gsub(path, '/', '\\')
  else
    return path
  end
end

function self.setDefaultPath(path)
  last_opened_path = path
end

function self.openDialog(default_path, filter, callback, overwrite_last_open)
  path = last_opened_path or default_path
  if default_path and overwrite_last_open then
    path = default_path
  end

  if callback then
    if self.supportWindowsInThreads() then
      local code = [[
        local channelName, path, filter = ...
        local channel = love.thread.getChannel(channelName)

        local nfd = require('lib.nfd_bind')

        local res = nfd.open(filter, path)
        channel:push(res)
      ]]

      return threads.createStartWithCallback(code, callback, path, filter)
    else
      local result = nfd.open(filter, path)

      if result then
        callback(result)
      end

      return false, false
    end
  else
    return nfd.open(filter, path)
  end
end

function self.saveDialog(default_path, filename, filter, callback, overwrite_last_open)
  path = last_opened_path or default_path
  if default_path and overwrite_last_open then
    path = default_path
  end

  if callback then
    if self.supportWindowsInThreads() then
      local code = [[
        local channelName, path, filter, filename = ...
        local channel = love.thread.getChannel(channelName)

        local nfd = require('lib.nfd_bind')

        local res = nfd.save(filter, path, filename)
        channel:push(res)
      ]]

      return threads.createStartWithCallback(code, callback, path, filter, filename)
    else
      callback(nfd.save(filter, path, filename))

      return false, false
    end
  else
    return nfd.save(filter, path)
  end
end

return self