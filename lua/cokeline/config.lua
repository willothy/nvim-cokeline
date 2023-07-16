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
    disable_mouse = false,
  },

  history = {
    enabled = true,
    size = 2,
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

  fill_hl = "TabLineFill",

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
        return buffer.filename
      end,
      style = function(buffer)
        if buffer.is_hovered and not buffer.is_focused then
          return "underline"
        end
        return nil
      end,
    },
    {
      text = " ",
    },
    {
      text = "",
      on_click = function(_, _, _, _, buffer)
        buffer:delete()
      end,
    },
    {
      text = " ",
    },
  },

  tabs = false,

  rhs = false,

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
        and not k:find("tabs")
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
  _G.cokeline.rhs = {}
  _G.cokeline.sidebar = {}
  _G.cokeline.tabs = {}
  if preferences.buffers and preferences.buffers.new_buffers_position then
    if not _G.cokeline.config.buffers then
      _G.cokeline.config.buffers = {}
    end
    _G.cokeline.config.buffers.new_buffers_position =
      preferences.buffers.new_buffers_position
  end
  local id = 1
  for _, component in ipairs(config.components) do
    local new_component = Component.new(component, id, config.default_hl)
    insert(_G.cokeline.components, new_component)
    if new_component.on_click ~= nil then
      require("cokeline/handlers").click:register(id, new_component.on_click)
    end
    id = id + 1
  end
  if config.rhs then
    for _, component in ipairs(config.rhs) do
      component.kind = "rhs"
      local new_component = Component.new(component, id, config.default_hl)
      insert(_G.cokeline.rhs, new_component)
      if new_component.on_click ~= nil then
        require("cokeline/handlers").click:register(id, new_component.on_click)
      end
      id = id + 1
    end
  end
  if config.sidebar and config.sidebar.components then
    for _, component in ipairs(config.sidebar.components) do
      component.kind = "sidebar"
      local new_component = Component.new(component, id, config.default_hl)
      insert(_G.cokeline.sidebar, new_component)
      if new_component.on_click ~= nil then
        require("cokeline/handlers").click:register(id, new_component.on_click)
      end
      id = id + 1
    end
  end
  if config.tabs and config.tabs.components then
    for _, component in ipairs(config.tabs.components) do
      component.kind = "tab"
      local new_component = Component.new(component, id, config.default_hl)
      insert(_G.cokeline.tabs, new_component)
      if new_component.on_click ~= nil then
        require("cokeline/handlers").click:register(id, new_component.on_click)
      end
      id = id + 1
    end
  end
  return config
end

return {
  get = get,
}
