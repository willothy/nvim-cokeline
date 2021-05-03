local vimcmd = vim.cmd
local format = string.format
local M = {}

local defaults = {
  hide_when_one_buffer = false,
  title_format = '{icon}{index}: {name} {flags}',
  use_devicons = false,
  highlights = {
    fill = {
      bg = '#3e4452'
    },
    buffers = {
      unfocused = {
        bg = '#3e4452',
        fg = '#abb2bf',
      },
      focused = {
        bg = '#abb2bf',
        fg = '#282c34',
      },
    },
  }
}

local function echoerr(msg)
  vimcmd(format('echoerr "[cokeline.nvim]: %s"', msg))
end

function M.update(preferences)
  local settings = defaults
  for k, v in pairs(preferences) do
    if defaults[k] ~= nil then
      settings[k] = v
    else
      echoerr(format('Configuration option "%s" does not exist!', k))
    end
  end
  return settings
end

return M
