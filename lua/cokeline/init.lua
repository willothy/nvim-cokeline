local bufferz = require('cokeline/buffers')
local augroups = require('cokeline/augroups')
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
local focused_line = {}

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
  -- TODO: refactor. This is way too complex to read. Maybe figure out a
  -- cleaner way to deal with buffers that aren't shown.
  local target_index
  if args.target then
    if args.target < 1 or args.target > #state.buffers then
      return
    end
    target_index = args.target
    local invisible_buffers_before_target = 0
    for i=1,target_index do
      if not state.buffers[i].__is_shown then
        invisible_buffers_before_target = invisible_buffers_before_target + 1
      end
    end
    target_index = target_index + invisible_buffers_before_target
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
  opt.showtabline = #fn.getbufinfo({buflisted = 1}) == 0 and 0 or 2
end

function M.focus(args)
  if opt.showtabline._value == 0 then
    state.buffers = bufferz.get_buffers(state.order)
  end
  if #state.buffers == 1 then
    return
  end
  local target_index = get_target_index(args)
  if not target_index or not state.buffers[target_index] then
    return
  end
  cmd('buffer ' .. state.buffers[target_index].number)
end

function M.switch(args)
  if opt.showtabline._value == 0 then
    state.buffers = bufferz.get_buffers(state.order)
  end
  if #state.buffers == 1 then
    return
  end
  local current_index = get_current_index()
  local target_index = get_target_index(args)
  if not target_index or not state.buffers[target_index] then
    return
  end
  local current_buffer = state.buffers[current_index]
  local target_buffer = state.buffers[target_index]
  state.buffers[current_index] = target_buffer
  state.buffers[target_index] = current_buffer
  state.order = map(function(buffer) return buffer.number end, state.buffers)
  redraw()
end

function M.setup(preferences)
  settings = defaults.merge(preferences)
  -- TODO: the default highlight groups for the components should be defined
  -- here, so that I can do componentz.setup(settings.components)
  -- hlgroups.setup(settings.default_hl)
  components = componentz.setup(settings)
  bufferz.setup(settings.buffers)
  augroups.setup()
  mappings.setup()
  opt.showtabline = 2
  opt.tabline = '%!v:lua.cokeline()'
end

function _G.cokeline()
  state.buffers = bufferz.get_buffers(state.order)
  local buffers = filter(function(b) return b.__is_shown end, state.buffers)

  if (settings.hide_when_one_buffer and #buffers == 1) or (#buffers == 0) then
    opt.showtabline = 0
    return
  end

  local cokeline = Cokeline:new()

  for _, buffer in pairs(buffers) do
    local line = Line:new(buffer)
    for _, component in pairs(components) do
      line:add_component(component:render(buffer))
    end
    -- TODO: refactor it so that this if is not necessary and define
    -- focused_line in cokeline.lua.
    if buffer.is_focused then
      focused_line = {
        width = line.width,
        index = buffer.index,
        colstart = cokeline.width + 1,
        colend = cokeline.width + line.width,
      }
    end
    cokeline:add_line(line)
  end

  cokeline:render(focused_line)

  return
    cokeline.before
    .. cokeline.main
    .. cokeline.after
end

return M
