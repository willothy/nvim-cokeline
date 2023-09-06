local lazy = require("cokeline.lazy")
local state = lazy("cokeline.state")
local sliders = lazy("cokeline.sliders")
local utils = lazy("cokeline.utils")

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
      text = "󰅖",
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

local config = vim.deepcopy(defaults)

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

local setup = function(opts)
  config = update(config, opts)
  state.components = {}
  state.rhs = {}
  state.sidebar = {}
  state.tabs = {}
  local Component = lazy("cokeline.components").Component
  if opts.buffers and opts.buffers.new_buffers_position then
    if not config.buffers then
      config.buffers = {}
    end
    config.buffers.new_buffers_position = opts.buffers.new_buffers_position
  end
  local id = 1
  for _, component in ipairs(opts.components) do
    local new_component = Component.new(component, id, opts.default_hl)
    insert(state.components, new_component)
    if new_component.on_click ~= nil then
      require("cokeline.handlers").click:register(id, new_component.on_click)
    end
    id = id + 1
  end
  if opts.rhs then
    for _, component in ipairs(opts.rhs) do
      component.kind = "rhs"
      local new_component = Component.new(component, id, opts.default_hl)
      insert(state.rhs, new_component)
      if new_component.on_click ~= nil then
        require("cokeline.handlers").click:register(id, new_component.on_click)
      end
      id = id + 1
    end
  end
  if opts.sidebar and opts.sidebar.components then
    for _, component in ipairs(opts.sidebar.components) do
      component.kind = "sidebar"
      local new_component = Component.new(component, id, opts.default_hl)
      insert(state.sidebar, new_component)
      if new_component.on_click ~= nil then
        require("cokeline.handlers").click:register(id, new_component.on_click)
      end
      id = id + 1
    end
  end
  if opts.tabs and opts.tabs.components then
    for _, component in ipairs(opts.tabs.components) do
      component.kind = "tab"
      local new_component = Component.new(component, id, opts.default_hl)
      insert(state.tabs, new_component)
      if new_component.on_click ~= nil then
        require("cokeline.handlers").click:register(id, new_component.on_click)
      end
      id = id + 1
    end
  end
  return config
end

return setmetatable({
  setup = setup,
  get = function()
    return config
  end,
}, {
  __index = function(_, k)
    return config[k]
  end,
  __newindex = function(_, k, v)
    config[k] = v
  end,
})
