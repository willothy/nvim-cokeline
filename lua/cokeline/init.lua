local bufferz = require('cokeline/buffers')
local augroups = require('cokeline/augroups')
local hlgroups = require('cokeline/hlgroups')
local defaults = require('cokeline/defaults')
local mappings = require('cokeline/mappings')
local componentz = require('cokeline/components')

local Line = require('cokeline/lines').Line
local Cokeline = require('cokeline/cokeline').Cokeline

local fn = vim.fn
local cmd = vim.cmd
local opt = vim.opt
local map = vim.tbl_map
local filter = vim.tbl_filter

local M = {}

local settings = {}
local components = {}

local state = {
  buffers = {},
  order = {},
}

local redraw = function()
  cmd('redrawtabline')
  cmd('redraw')
end

local get_current_index = function()
  local current_buffer_number = fn.bufnr('%')
  for index, buffer in ipairs(state.buffers) do
    if current_buffer_number == buffer.number then
      return index
    end
  end
end

local get_target_index = function(args)
  if opt.showtabline._value == 0 then
    state.buffers = bufferz.get_buffers(state.order)
  end

  local target_index

  if args.target then
    for i, buffer in ipairs(state.buffers) do
      if buffer.index == args.target and buffer.__is_shown then
        target_index = i
      end
    end
  else
    local current_index = get_current_index()
    if not current_index then
      return
    end
    target_index = current_index + args.step
    if target_index < 1 or target_index > #state.buffers then
      if settings.cycle_prev_next_mappings then
        target_index = (target_index - 1) % #state.buffers + 1
      else
        return
      end
    end
  end

  return target_index
end

function M.toggle()
  opt.showtabline = (#fn.getbufinfo({buflisted = 1}) > 0) and 2 or 0
end

function M.focus(args)
  local target = get_target_index(args)
  if not target then
    return
  end
  cmd('buffer ' .. state.buffers[target].number)
end

function M.switch(args)
  local target = get_target_index(args)
  if not target then
    return
  end
  local current = get_current_index()
  state.buffers[current], state.buffers[target]
    = state.buffers[target], state.buffers[current]
  state.order = map(function(buffer) return buffer.number end, state.buffers)
  redraw()
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
  state.buffers = bufferz.get_buffers(state.order)
  local buffers = filter(function(b) return b.__is_shown end, state.buffers)

  if (#buffers == 0) or (settings.hide_when_one_buffer and #buffers == 1) then
    opt.showtabline = 0
    return
  end

  local cokeline = Cokeline:new()

  for _, buffer in pairs(buffers) do
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
