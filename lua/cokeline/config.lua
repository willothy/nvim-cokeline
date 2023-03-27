local Component = require("cokeline/components").Component
local sliders = require("cokeline/sliders")
local utils = require("cokeline/utils")

local insert = table.insert

local echo = vim.api.nvim_echo
local islist = vim.tbl_islist

local defaults = {
  show_if_buffers_are_at_least = 1,

  buffers = {
    filter_valid = false,
    filter_visible = false,
    focus_on_delete = "next",
    new_buffers_position = "last",
    delete_on_right_click = true,
  },

  mappings = {
    cycle_prev_next = true,
  },

  rendering = {
    max_buffer_width = 999,
    slider = sliders.center_current_buffer,
  },

  pick = {
    use_filename = true,
    letters = "asdfjkl;ghnmxcvbziowerutyqpASDFJKLGHNMXCVBZIOWERUTYQP",
  },

  default_hl = {
    fg = function(buffer)
      return buffer.is_focused and utils.get_hex("ColorColumn", "bg")
        or utils.get_hex("Normal", "fg")
    end,
    bg = function(buffer)
      return buffer.is_focused and utils.get_hex("Normal", "fg")
        or utils.get_hex("ColorColumn", "bg")
    end,
    style = "NONE",
  },

  ---@type Component[]
  components = {
    {
      text = function(buffer)
        return " " .. buffer.devicon.icon
      end,
      fg = function(buffer)
        return buffer.devicon.color
      end,
    },
    {
      text = function(buffer)
        return buffer.unique_prefix
      end,
      fg = utils.get_hex("Comment", "fg"),
      style = "italic",
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

  sidebar = false,
}

-- Formats an error message.
---@param msg  string
local echoerr = function(msg)
  echo({
    { "[nvim-cokeline]: ", "ErrorMsg" },
    { 'Configuration option "' },
    { msg, "WarningMsg" },
    { '" does not exist!' },
  }, true, {})
end

-- Updates the `settings` table with options from `preferences`, printing an
-- error message if a configuration option in `preferences` is not defined in
-- `settings`.
---@param settings  table
---@param preferences  table
---@param key  string | nil
---@return table
local function update(settings, preferences, key)
  local updated = settings
  for k, v in pairs(preferences) do
    local key_tree = key and ("%s.%s"):format(key, k) or k
    if settings[k] == nil then
      echoerr(key_tree)
    else
      updated[k] = (
        type(v) == "table"
        and not islist(v)
        and not k:find("sidebar")
      )
          and update(settings[k], v, key_tree)
        or v
    end
  end
  return updated
end

local get = function(preferences)
  local config = update(defaults, preferences)
  _G.cokeline.components = {}
  for i, component in ipairs(config.components) do
    local new_component = Component.new(component, i, config.default_hl)
    insert(_G.cokeline.components, new_component)
    if new_component.on_click ~= nil then
      require("cokeline/handlers").click:register(i, new_component.on_click)
    end
  end
  return config
end

return {
  get = get,
}
