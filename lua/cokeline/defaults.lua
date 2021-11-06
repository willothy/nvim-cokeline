local utils = require('cokeline/utils')
local echoerr = utils.echoerr
local get_hex = utils.get_hex

local M = {}

local defaults = {
  hide_when_one_buffer = false,
  cycle_prev_next_mappings = false,

  rendering = {
    min_line_width = nil,
    max_line_width = nil,
  },

  buffers = {
    filter = nil,
  },

  default_hl = {
    focused = {
      fg = get_hex('ColorColumn', 'bg'),
      bg = get_hex('Normal', 'fg'),
    },

    unfocused = {
      fg = get_hex('Normal', 'fg'),
      bg = get_hex('ColorColumn', 'bg'),
    },
  },

  components = {
    {
      text = function(buffer) return ' ' .. buffer.devicon.icon end,
      hl = {
        fg = function(buffer) return buffer.devicon.color end,
      },
    },
    {
      text = function(buffer) return buffer.unique_prefix end,
      hl = {
        fg = get_hex('Comment', 'fg'),
        style = 'italic',
      },
    },
    {
      text = function(buffer) return buffer.filename .. ' ' end,
    },
    {
      text = '',
      delete_buffer_on_left_click = true,
    },
    {
      text = ' ',
    }
  },
}

function M.merge(preferences)
  local settings = defaults

  for option, value in pairs(preferences) do
    if defaults[option] ~= nil then
      settings[option] = value
    else
      echoerr(('Configuration option "%s" does not exist!'):format(option))
    end
  end

  return settings
end

return M
