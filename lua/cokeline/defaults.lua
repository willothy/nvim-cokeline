local rq_sliders = require("cokeline/sliders")
local rq_utils = require("cokeline/utils")

local vim_echo = vim.api.nvim_echo
local vim_tbl_islist = vim.tbl_islist

local defaults = {
  show_if_buffers_are_at_least = 1,

  buffers = {
    filter_valid = false,
    filter_visible = false,
    focus_on_delete = false,
    new_buffers_position = "last",
  },

  mappings = {
    cycle_prev_next = true,
  },

  rendering = {
    max_buffer_width = 999,
    slider = rq_sliders.center_current_buffer,
    left_sidebar = false,
    right_sidebar = false,
  },

  ---@type table<string, Hl>
  default_hl = {
    focused = {
      fg = rq_utils.get_hex("ColorColumn", "bg"),
      bg = rq_utils.get_hex("Normal", "fg"),
      style = "NONE",
    },

    unfocused = {
      fg = rq_utils.get_hex("Normal", "fg"),
      bg = rq_utils.get_hex("ColorColumn", "bg"),
      style = "NONE",
    },
  },

  ---@type Cmp[]
  components = {
    {
      text = function(buffer)
        return " " .. buffer.devicon.icon
      end,
      hl = {
        fg = function(buffer)
          return buffer.devicon.color
        end,
      },
    },
    {
      text = function(buffer)
        return buffer.unique_prefix
      end,
      hl = {
        fg = rq_utils.get_hex("Comment", "fg"),
        style = "italic",
      },
    },
    {
      text = function(buffer)
        return buffer.filename .. " "
      end,
    },
    {
      text = "",
      delete_buffer_on_left_click = true,
    },
    {
      text = " ",
    },
  },
}

---Formats an error message.
---@param msg  string
local echoerr = function(msg)
  vim_echo({ { ("[nvim-cokeline]: %s"):format(msg), "ErrorMsg" } }, true, {})
end

---Updates the `settings` table with options from `preferences`, printing an
---error message if a configuration option in `preferences` is not defined in
---`settings`.
---@param settings  table
---@param preferences  table
---@param key  string | nil
---@return table
local update
update = function(settings, preferences, key)
  local updated = settings
  for k, v in pairs(preferences) do
    local key_tree = key and ("%s.%s"):format(key, k) or k
    if settings[k] == nil then
      echoerr(('Configuration option "%s" does not exist!'):format(key_tree))
    else
      updated[k] = (
            type(v) == "table"
            and not vim_tbl_islist(v)
            and not k:find("sidebar")
          )
          and update(settings[k], v, key_tree)
        or v
    end
  end
  return updated
end

return {
  update = function(preferences)
    return update(defaults, preferences)
  end,
}
