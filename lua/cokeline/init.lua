local buffers = require('cokeline/buffers')
local rendering = require('cokeline/rendering')
local setup_buffers = buffers.setup
local setup_rendering = rendering.setup
local setup_augroups = require('cokeline/augroups').setup
local setup_hlgroups = require('cokeline/hlgroups').setup
local update_defaults = require('cokeline/defaults').update
local setup_mappings = require('cokeline/mappings').setup
local setup_components = require('cokeline/components').setup

local cmd = vim.cmd
local opt = vim.opt

local M = {}

local settings, valid_buffers, visible_buffers, bufnrs

---@return vidx|nil
local get_current_vidx = function()
  for _, buffer in pairs(valid_buffers) do
    if buffer.is_focused then return buffer._vidx end
  end
end

---@alias step '1'|'-1'

---@param current vidx
---@param step    step
---@return vidx|nil
local get_vidx_from_step = function(current, step)
  local target = current + step
  if target < 1 or target > #valid_buffers then
    if not settings.cycle_prev_next_mappings then return end
    return (target - 1) % #valid_buffers + 1
  end
  return target
end

---@param index index
---@return vidx|nil
local get_vidx_from_index = function(index)
  for _, buffer in pairs(visible_buffers) do
    if buffer.index == index then return buffer._vidx end
  end
end

---@param vidx1 vidx
---@param vidx2 vidx
local switch_buffer_order = function(vidx1, vidx2)
  bufnrs[vidx1], bufnrs[vidx2] = bufnrs[vidx2], bufnrs[vidx1]
  cmd('redrawtabline | redraw')
end

---@param step step
M.switch_by_step = function(step)
  if opt.showtabline._value == 0 then
    valid_buffers, visible_buffers = buffers.get_bufinfos(bufnrs)
  end
  local current = get_current_vidx()
  if not current then return end
  local target = get_vidx_from_step(current, step)
  if not target then return end
  switch_buffer_order(current, target)
end

---@param index index
M.switch_by_index = function(index)
  local current = get_current_vidx()
  if not current then return end
  local target = get_vidx_from_index(index)
  if not target then return end
  switch_buffer_order(current, target)
end

---@param bufnr bufnr
local focus_buffer = function(bufnr)
  cmd('buffer ' .. bufnr)
end

---@param step step
M.focus_by_step = function(step)
  if opt.showtabline._value == 0 then
    valid_buffers, visible_buffers = buffers.get_bufinfos(bufnrs)
  end
  local current = get_current_vidx()
  if not current then return end
  local target = get_vidx_from_step(current, step)
  if not target then return end
  focus_buffer(valid_buffers[target].number)
end

---@param index index
M.focus_by_index = function(index)
  local target = get_vidx_from_index(index)
  if not target then return end
  focus_buffer(valid_buffers[target].number)
end

M.toggle = function()
  valid_buffers, _ = buffers.get_bufinfos(bufnrs)
  opt.showtabline = (#valid_buffers > 0) and 2 or 0
end

---@param preferences table
M.setup = function(preferences)
  settings = update_defaults(preferences)
  local components = setup_components(settings.components)
  setup_rendering(settings.rendering, components)
  setup_hlgroups(settings.default_hl)
  setup_buffers(settings.buffers)
  setup_augroups()
  setup_mappings()
  opt.showtabline = 2
  opt.tabline = '%!v:lua.cokeline()'
end

---@return string
_G.cokeline = function()
  valid_buffers, visible_buffers, bufnrs = buffers.get_bufinfos(bufnrs)
  if #visible_buffers < settings.show_if_buffers_are_at_least then
    opt.showtabline = 0
    return
  end
  return rendering.render(visible_buffers)
end

return M
