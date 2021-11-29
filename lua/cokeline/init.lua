local buffers = require('cokeline/buffers')
local rendering = require('cokeline/rendering')
local setup_buffers = buffers.setup
local setup_rendering = rendering.setup
local setup_augroups = require('cokeline/augroups').setup
local setup_hlgroups = require('cokeline/hlgroups').setup
local update_defaults = require('cokeline/defaults').update
local setup_mappings = require('cokeline/mappings').setup
local setup_components = require('cokeline/components').setup

local opt = vim.opt

---WARNING(state): this variable is used as global immutable state
---@type table
local settings

---@param preferences table
local setup = function(preferences)
  settings = update_defaults(preferences)
  local components = setup_components(settings.components)
  setup_rendering(settings.rendering, components)
  setup_hlgroups(settings.default_hl)
  setup_buffers(settings.buffers, settings.cycle_prev_next_mappings)
  setup_augroups()
  setup_mappings()
  opt.showtabline = 2
  opt.tabline = '%!v:lua.cokeline()'
end

---@return string
_G.cokeline = function()
  local fetch_start = vim.fn.reltime()
  local visible_buffers = buffers.get_visible_buffers()
  if #visible_buffers < settings.show_if_buffers_are_at_least then
    opt.showtabline = 0
    return
  end
  local fetch_stop = vim.fn.reltime()
  local fetch_time = vim.fn.reltimefloat(vim.fn.reltime(fetch_start, fetch_stop)) * 1000
  -- print(('Fetching took %s ms'):format(fetch_time))

  local render_start = vim.fn.reltime()
  local cokeline = rendering.render(visible_buffers)
  local render_stop = vim.fn.reltime()
  local render_time = vim.fn.reltimefloat(vim.fn.reltime(render_start, render_stop)) * 1000
  -- print(('Rendering took %s ms'):format(render_time))

  -- print(('Total took %s ms'):format(render_time + fetch_time))

  return cokeline
end

return {
  setup = setup,
}
