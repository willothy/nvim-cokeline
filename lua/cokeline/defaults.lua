local get_hex = require('cokeline/hlgroups').get_hex

local format = string.format

local M = {}

local defaults = {
  hide_when_one_buffer = false,
  cycle_prev_next_mappings = false,
  same_size_tabs = true,

  focused_fg = get_hex('ColorColumn', 'fg'),
  focused_bg = get_hex('Normal', 'fg'),
  unfocused_fg = get_hex('Normal', 'fg'),
  unfocused_bg = get_hex('ColorColumn', 'fg'),

  components = {
    {
      text = '｜',
      hl = {
        fg = get_hex('String', 'fg'),
        -- fg = function(buffer)
        --   return
        --     buffer.is_modified
        --     and get_hex('String', 'fg')
        --     or get_hex('Error', 'fg')
        -- end
      },
    },
    {
      text = function(buffer) return buffer.devicon end,
      hl = {
        fg = function(buffer) return buffer.devicon_color end,
      },
    },
    {
      text = function(buffer) return format('%s: ', buffer.index) end,
    },
    {
      text = function(buffer) return buffer.unique_prefix end,
      hl = {
        fg = get_hex('Comment', 'fg'),
        style = 'italic',
      },
    },
    {
      text = function(buffer) return buffer.filename end,
    },
    {
      text = ' ',
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
