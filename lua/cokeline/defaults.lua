local utils = require('cokeline/utils')

local M = {}

local defaults = {
  hide_when_one_buffer = false,
  cycle_prev_next_mappings = false,
  same_size_tabs = true,

  default_hl = {
    focused = {
      fg = utils.get_hex('ColorColumn', 'bg'),
      bg = utils.get_hex('Normal', 'fg'),
    },
    unfocused = {
      fg = utils.get_hex('Normal', 'fg'),
      bg = utils.get_hex('ColorColumn', 'bg'),
    },
  },

  components = {
    {
      text = function(buffer) return buffer.devicon .. ' ' end,
      hl = {
        fg = function(buffer) return buffer.devicon_color end,
      },
    },
    {
      text = function(buffer) return buffer.index .. ': ' end,
    },
    {
      text = function(buffer) return buffer.unique_prefix end,
      hl = {
        fg = utils.get_hex('Comment', 'fg'),
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

  local echoerr = function(msg)
    local fmt = '[cokeline.nvim]: %s'
    vim.api.nvim_echo({{fmt:format(msg), 'ErrorMsg'}}, true, {})
  end

  for k, v in pairs(preferences) do
    if defaults[k] ~= nil then
      settings[k] = v
    else
      local msg = 'Configuration option "%s" does not exist!'
      echoerr(msg:format(k))
    end
  end

  return settings
end

return M
