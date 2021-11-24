local get_hex = require('cokeline/utils').get_hex

local echo = vim.api.nvim_echo

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
      style = 'NONE',
    },

    unfocused = {
      fg = get_hex('Normal', 'fg'),
      bg = get_hex('ColorColumn', 'bg'),
      style = 'NONE',
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

---Formats an error message.
---@param msg  string
local echoerr = function(msg)
  echo({{('[cokeline.nvim]: %s'):format(msg), 'ErrorMsg'}}, true, {})
end

---Checks if `t` is a list table.
---@param t  table
---@return boolean
local is_list_table = function(t)
  return t[1] and true or false
end

---Updates the `settings` table with options from `preferences`, printing an
---error message if a configuration option in `preferences` is not defined in
---`settings`.
---@param settings  table
---@param preferences  table
---@param key  string|nil
---@return table
local update
update = function(settings, preferences, key)
  local updated = settings
  for k, v in pairs(preferences) do
    local key_tree = key and ('%s.%s'):format(key, k) or k
    if settings[k] == nil then
      echoerr(('Configuration option "%s" does not exist!'):format(key_tree))
    else
      updated[k] =
        (type(v) == 'table' and not is_list_table(v))
        and update(settings[k], v, key_tree)
         or v
    end
  end
  return updated
end

M.update = function(preferences)
  return update(defaults, preferences)
end

return M
