local lazy = require("cokeline.lazy")
local rendering = lazy("cokeline.rendering")
local history = lazy("cokeline.history")
local config = lazy("cokeline.config")

local opt = vim.opt

_G.cokeline = {}

---@param opts table|nil
local setup = function(opts)
  config.setup(opts or {})
  if config.history and config.history.enabled then
    history.setup(config.history.size)
  end

  require("cokeline.augroups").setup()
  require("cokeline.mappings").setup()
  require("cokeline.hover").setup()

  opt.showtabline = 2
  opt.tabline = "%!v:lua.cokeline.tabline()"
end

---@return string
_G.cokeline.tabline = function()
  local visible_buffers = require("cokeline.buffers").get_visible()
  if #visible_buffers < config.show_if_buffers_are_at_least then
    opt.showtabline = 0
    return ""
  end
  return rendering.render(visible_buffers, config.fill_hl)
end

return {
  setup = setup,
}
