local rq_augroups = require('cokeline/augroups')
local rq_buffers = require('cokeline/buffers')
local rq_components = require('cokeline/components')
local rq_defaults = require('cokeline/defaults')
local rq_mappings = require('cokeline/mappings')
local rq_rendering = require('cokeline/rendering')

local vim_opt = vim.opt

local gl_settings

---@param preferences table
local setup = function(preferences)
  gl_settings = rq_defaults.update(preferences)
  rq_augroups.setup()
  rq_buffers.setup(gl_settings.buffers)
  rq_mappings.setup(gl_settings.mappings)
  local comps = rq_components.cmps_to_comps(gl_settings.components)
  rq_rendering.setup(gl_settings.rendering, gl_settings.default_hl, comps)
  vim_opt.showtabline = 2
  vim_opt.tabline = '%!v:lua.cokeline()'
end

---@return string
_G.cokeline = function()
  local visible_buffers = rq_buffers.get_visible_buffers()
  if #visible_buffers < gl_settings.show_if_buffers_are_at_least then
    vim_opt.showtabline = 0
    return
  end
  return rq_rendering.render(visible_buffers)
end

return {
  setup = setup,
}
