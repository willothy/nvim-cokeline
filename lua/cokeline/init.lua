local opt = vim.opt

_G.cokeline = {}

---@param opts table|nil
local setup = function(opts)
  local config = require("cokeline.config")
  config.setup(opts or {})

  local history = require("cokeline.history")
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
  if require("cokeline.state").cache then
    return require("cokeline.state").cache
  end
  local rendering = require("cokeline.rendering")
  local config = require("cokeline.config")
  local visible_buffers = require("cokeline.buffers").get_visible()
  if
    #visible_buffers < config.show_if_buffers_are_at_least
    or #visible_buffers == 0
  then
    opt.showtabline = 0
    return ""
  end
  require("cokeline.state").cache =
    rendering.render(visible_buffers, config.fill_hl)
  return require("cokeline.state").cache
end

return {
  setup = setup,
}
