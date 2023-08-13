local augroups = require("cokeline.augroups")
local buffers = require("cokeline.buffers")
local config = require("cokeline.config")
local mappings = require("cokeline.mappings")
local rendering = require("cokeline.rendering")
local hover = require("cokeline.hover")
local history = require("cokeline.history")

local opt = vim.opt

---Global table used to manage the plugin's state.
_G.cokeline = {
  ---@type Component<Buffer>[]
  components = {},

  ---@type Component<RhsContext>[]
  rhs = {},

  ---@type Component<SidebarContext>[]
  sidebar = {},

  ---@type Component<TabPage>[]
  tabs = {},

  ---@type table
  config = {},

  ---@type fun(): string
  tabline = nil,

  ---@type TabPage[]
  tab_cache = {},

  ---@type table<tabpage, TabPage>
  tab_lookup = {},

  ---@type Buffer[]
  valid_buffers = {},

  ---@type table<buffer, Buffer>
  valid_lookup = {},

  ---@type Buffer[]
  visible_buffers = {},

  ---@type table<buffer, valid_index>
  buf_order = {},

  ---@type Cokeline.History
  history = nil,

  __handlers = require("cokeline.handlers"),
}

--@param preferences table|nil
---@param preferences Component<TabPage>
local setup = function(preferences)
  _G.cokeline.config = config.get(preferences or {})
  if _G.cokeline.config.history.enabled then
    history.setup(_G.cokeline.config.history.size)
    _G.cokeline.history = history
  end

  local ok, _ = pcall(require, "plenary")
  if not ok then
    vim.api.nvim_err_writeln(
      "nvim-cokeline: plenary.nvim is required to use this plugin as of v0.4.0"
    )
    return
  end

  augroups.setup()
  mappings.setup()
  hover.setup()

  opt.showtabline = 2
  opt.tabline = "%!v:lua.cokeline.tabline()"
end

---@return string
_G.cokeline.tabline = function()
  local visible_buffers = buffers.get_visible()
  if
    #visible_buffers < _G.cokeline.config.show_if_buffers_are_at_least
    or #visible_buffers == 0
  then
    opt.showtabline = 0
    return
  end
  return rendering.render(visible_buffers, _G.cokeline.config.fill_hl)
end

return {
  setup = setup,
}
