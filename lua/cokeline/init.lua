local buffers = require('cokeline/buffers')
local rendering = require('cokeline/rendering')
local setup_buffers = buffers.setup
local setup_rendering = rendering.setup
local setup_augroups = require('cokeline/augroups').setup
local setup_hlgroups = require('cokeline/hlgroups').setup
local defaults_merge = require('cokeline/defaults').merge
local setup_mappings = require('cokeline/mappings').setup
local setup_components = require('cokeline/components').setup

local map = vim.tbl_map
local cmd = vim.cmd
local opt = vim.opt

local M = {}

local settings, valid_buffers, visible_buffers

---@return number[]
local get_bufnr_order = function()
  return not valid_buffers and {} or map(function(buffer)
    return buffer.number
  end, valid_buffers)
end

---@return number|nil
local get_current_index = function()
  for _, buffer in pairs(valid_buffers) do
    if buffer.is_focused then return buffer.order end
  end
end

---@param current number
---@param step    number
---@return number|nil
local get_index_from_step = function(current, step)
  local target = current + step
  if target < 1 or target > #valid_buffers then
    if not settings.cycle_prev_next_mappings then return end
    return (target - 1) % #valid_buffers + 1
  end
  return target
end

---@param target number
---@return number|nil
local get_index_from_target = function(target)
  for _, buffer in pairs(visible_buffers) do
    if buffer.index == target then return buffer.order end
  end
end

---@param current number
---@param target  number
local switch_buffer_order = function(current, target)
  valid_buffers[current], valid_buffers[target]
    = valid_buffers[target], valid_buffers[current]
  cmd('redrawtabline | redraw')
end

---@param step number
M.switch_by_step = function(step)
  if opt.showtabline._value == 0 then
    valid_buffers, visible_buffers = buffers.get_bufinfos(get_bufnr_order())
  end
  local current_index = get_current_index()
  if not current_index then return end
  local target_index = get_index_from_step(current_index, step)
  if not target_index then return end
  switch_buffer_order(current_index, target_index)
end

---@param target number
M.switch_by_target = function(target)
  local current_index = get_current_index()
  if not current_index then return end
  local target_index = get_index_from_target(target)
  if not target_index then return end
  switch_buffer_order(current_index, target_index)
end

---@param bufnr number
local focus_buffer = function(bufnr)
  cmd('buffer ' .. bufnr)
end

---@param step number
M.focus_by_step = function(step)
  if opt.showtabline._value == 0 then
    valid_buffers, visible_buffers = buffers.get_bufinfos(get_bufnr_order())
  end
  local current_index = get_current_index()
  if not current_index then return end
  local target_index = get_index_from_step(current_index, step)
  if not target_index then return end
  focus_buffer(valid_buffers[target_index].number)
end

---@param target number
M.focus_by_target = function(target)
  local target_index = get_index_from_target(target)
  if not target_index then return end
  focus_buffer(valid_buffers[target_index].number)
end

M.toggle = function()
  valid_buffers, _ = buffers.get_bufinfos(get_bufnr_order())
  opt.showtabline = (#valid_buffers > 0) and 2 or 0
end

---@param preferences table
M.setup = function(preferences)
  settings = defaults_merge(preferences)
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
  valid_buffers, visible_buffers = buffers.get_bufinfos(get_bufnr_order())
  if #visible_buffers < settings.show_if_buffers_are_at_least then
    opt.showtabline = 0
    return
  end
  return rendering.render(visible_buffers)
end

return M
