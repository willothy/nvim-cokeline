local bufferz = require('cokeline/buffers')
local augroups = require('cokeline/augroups')
local hlgroups = require('cokeline/hlgroups')
local defaults = require('cokeline/defaults')
local mappings = require('cokeline/mappings')
local componentz = require('cokeline/components')

local Cokeline = require('cokeline/cokeline').Cokeline
local Line = require('cokeline/lines').Line

local cmd = vim.cmd
local opt = vim.opt
local fn = vim.fn

local M = {}

local buffers = {
  order = {},
  valid = {},
  visible = {},
}

local components = {}

local settings = {}

local get_current_index = function()
  local current_buffer_number = fn.bufnr('%')
  for index, buffer in ipairs(buffers.valid) do
    if current_buffer_number == buffer.number then
      return index
    end
  end
end

local get_target_index = function(args)
  if opt.showtabline._value == 0 then
    buffers = bufferz.get_buffers(buffers.order)
  end

  local target_index

  if args.target then
    for i, buffer in ipairs(buffers.valid) do
      if buffer.index == args.target and buffer.__is_shown then
        target_index = i
        break
      end
    end
  else
    local current_index = get_current_index()
    if not current_index then
      return
    end
    target_index = current_index + args.step
    if target_index < 1 or target_index > #buffers.valid then
      if not settings.cycle_prev_next_mappings then
        return
      end
      target_index = (target_index - 1) % #buffers.valid + 1
    end
  end

  return target_index
end

function M.toggle()
  buffers = bufferz.get_buffers(buffers.order)
  opt.showtabline = (#buffers.valid > 0) and 2 or 0
end

function M.focus(args)
  local target = get_target_index(args)
  if not target then
    return
  end
  cmd('buffer ' .. buffers.order[target])
end

function M.switch(args)
  local target = get_target_index(args)
  if not target then
    return
  end
  local current = get_current_index()
  buffers.order[current], buffers.order[target]
    = buffers.order[target], buffers.order[current]
  cmd('redrawtabline | redraw')
end

function M.setup(preferences)
  settings = defaults.merge(preferences)
  augroups.setup()
  mappings.setup()
  bufferz.setup(settings.buffers)
  hlgroups.setup(settings.default_hl)
  components = componentz.setup(settings.components)
  opt.showtabline = 2
  opt.tabline = '%!v:lua.cokeline()'
end

function _G.cokeline()
  buffers = bufferz.get_buffers(buffers.order)
  local visible = buffers.visible

  if (#visible == 0) or (#visible == 1 and settings.hide_when_one_buffer) then
    opt.showtabline = 0
    return
  end

  local cokeline = Cokeline:new()

  for _, buffer in pairs(visible) do
    local line = Line:new(buffer)
    for _, component in pairs(components) do
      line:add_component(component:render(buffer))
    end
    cokeline:add_line(line)
  end

  cokeline:render(settings.rendering)

  return
    cokeline.before
    .. cokeline.main
    .. cokeline.after
end

return M
