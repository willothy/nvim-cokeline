local lazy = require("cokeline.lazy")
---@module cokeline.state
local state = lazy("cokeline.state")
---@module "cokeline.sliders"
local sliders = lazy("cokeline.sliders")
---@module "cokeline.hlgroups"
local hlgroups = lazy("cokeline.hlgroups")

local insert = table.insert

local echo = vim.api.nvim_echo
local islist = vim.islist or vim.tbl_islist

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
      return buffer.is_focused and "TabLineSel" or "TabLine"
    end,
    bg = function(buffer)
      return buffer.is_focused and "TabLineSel" or "TabLine"
    end,
  },

  fill_hl = "TabLineFill",

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
      fg = function()
        return hlgroups.get_hl_attr("Comment", "fg")
      end,
      italic = true,
    },
    {
      text = function(buffer)
        return buffer.filename
      end,
      underline = function(buffer)
        if buffer.is_hovered and not buffer.is_focused then
          return true
        end
      end,
    },
    {
      text = " ",
    },
    {
      ---@param buffer Buffer
      text = function(buffer)
        if buffer.is_modified then
          return ""
        end
        if buffer.is_hovered then
          return "󰅙"
        end
        return "󰅖"
      end,
      on_click = function(_, _, _, _, buffer)
        buffer:delete()
      end,
    },
    {
      text = " ",
    },
  },

  tabs = {
    placement = "right",
    components = {},
  },

  rhs = {},

  sidebar = {
    filetype = { "NvimTree", "neo-tree", "SidebarNvim" },
    components = {},
  },
}

-- Formats an error message.
---@param msg  string
local echoerr = function(msg)
  echo({
    { "[nvim-cokeline]: ",     "ErrorMsg" },
    { 'Configuration option "' },
    { msg,                     "WarningMsg" },
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
    if settings[k] == nil and key ~= "default_hl" then
      echoerr(key_tree)
    elseif type(v) == "table" and not islist(v) then
      updated[k] = update(settings[k], v, key_tree)
    else
      updated[k] = v
    end
  end
  return updated
end

local setup = function(opts)
  config = update(defaults, opts)
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
  for _, component in ipairs(config.components) do
    local new_component = Component.new(component, id, opts.default_hl)
    insert(state.components, new_component)
    if new_component.on_click ~= nil then
      require("cokeline.handlers").click:register(id, new_component.on_click)
    end
    id = id + 1
  end
  if opts.rhs then
    for _, component in ipairs(config.rhs) do
      component.kind = "rhs"
      local new_component = Component.new(component, id, opts.default_hl)
      insert(state.rhs, new_component)
      if new_component.on_click ~= nil then
        require("cokeline.handlers").click:register(id, new_component.on_click)
      end
      id = id + 1
    end
  end
  if config.sidebar and config.sidebar.components then
    for _, component in ipairs(config.sidebar.components) do
      component.kind = "sidebar"
      local new_component = Component.new(component, id, opts.default_hl)
      insert(state.sidebar, new_component)
      if new_component.on_click ~= nil then
        require("cokeline.handlers").click:register(id, new_component.on_click)
      end
      id = id + 1
    end
  end
  if config.tabs and config.tabs.components then
    for _, component in ipairs(config.tabs.components) do
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
