local augroups = require("cokeline/augroups")
local buffers = require("cokeline/buffers")
local components = require("cokeline/components")
local defaults = require("cokeline/defaults")
local mappings = require("cokeline/mappings")
local rendering = require("cokeline/rendering")

local vim_opt = vim.opt

_G.cokeline = {
  ---@type Buffer[]
  valid_buffers = {},

  ---@type Buffer[]
  visible_buffers = {},

  --@type fun(): string
  tabline = {},
}

local gl_settings = {}

---@param preferences  table | nil
local setup = function(preferences)
  gl_settings = defaults.update(preferences or {})
  augroups.setup({ focus_on_delete = gl_settings.buffers.focus_on_delete })
  buffers.setup(gl_settings.buffers)
  mappings.setup(gl_settings.mappings)
  local comps = components.cmps_to_comps(gl_settings.components)
  rendering.setup(gl_settings.rendering, gl_settings.default_hl, comps)
  vim_opt.showtabline = 2
  vim_opt.tabline = "%!v:lua.cokeline.tabline()"
end

---@return string
_G.cokeline.tabline = function()
  local visible_buffers = buffers.get_visible_buffers()
  if #visible_buffers < gl_settings.show_if_buffers_are_at_least then
    vim_opt.showtabline = 0
    return
  end
  return rendering.render(visible_buffers)
end

return {
  setup = setup,
}
