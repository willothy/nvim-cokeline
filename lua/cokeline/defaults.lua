local get_hex = require('cokeline/utils').get_hex

local M = {}

local defaults = {
  hide_when_one_buffer = false,
  cycle_prev_next_mappings = false,

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
