local utils = require('cokeline/utils')
local get_hex = utils.get_hex
local update = utils.update

local M = {}

local defaults = {
  show_if_buffers_are_at_least = 1,
  cycle_prev_next_mappings = false,

  rendering = {
    min_line_width = 0,
    max_line_width = 999,
  },

  buffers = {
    filter = false,
    new_buffers_position = 'last',
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

M.update = function(preferences)
  return update(defaults, preferences)
end

return M
