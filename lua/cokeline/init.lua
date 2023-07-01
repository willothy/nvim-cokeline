local augroups = require("cokeline/augroups")
local buffers = require("cokeline/buffers")
local config = require("cokeline/config")
local mappings = require("cokeline/mappings")
local rendering = require("cokeline/rendering")
local hover = require("cokeline/hover")
local history = require("cokeline/history")

local opt = vim.opt

---Global table used to manage the plugin's state.
_G.cokeline = {
  ---@type Component[]
  components = {},

  ---@type Component[]
  rhs = {},

  ---@type Component[]
  sidebar = {},

  ---@type table
  config = {},

  ---@type fun(): string
  tabline = nil,

  ---@type Buffer[]
  valid_buffers = {},

  ---@type table<bufnr, Buffer>
  valid_lookup = {},

  ---@type Buffer[]
  visible_buffers = {},

  ---@type table<bufnr, valid_index>
  buf_order = {},

  ---@type Cokeline.History
  history = nil,

  __handlers = require("cokeline/handlers"),
}

---@param preferences table|nil
local setup = function(preferences)
  _G.cokeline.config = config.get(preferences or {})
  if _G.cokeline.config.history.enabled then
    history.setup(_G.cokeline.config.history.size)
    _G.cokeline.history = history
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
