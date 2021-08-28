local augroups = require('cokeline/augroups')
local buffers = require('cokeline/buffers')
local componentz = require('cokeline/components')
local defaults = require('cokeline/defaults')
local mappings = require('cokeline/mappings')

local format = string.format
local concat = table.concat
local insert = table.insert

local cmd = vim.cmd
local fn = vim.fn
local opt = vim.opt
local map = vim.tbl_map

local M = {}

local components = {}
local settings = {}

local state = {
  buffers = {},
  order = {},
}

local get_current_index = function()
  local current_buffer_number = fn.bufnr('%')
  for index, buffer in ipairs(state.buffers) do
    if current_buffer_number == buffer.number then
      return index
    end
  end
end

local get_target_index = function(args)
  local target_index
  if args.target then
    if args.target < 1 or args.target > #state.buffers then
      return
    end
    target_index = args.target
  else
    local current_index = get_current_index()
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

local redraw = function()
  cmd('redrawtabline')
  cmd('redraw')
end

function M.toggle()
  opt.showtabline = #fn.getbufinfo({buflisted = 1}) > 1 and 2 or 0
end

function M.focus(args)
  local target_index = get_target_index(args)
  if not target_index then
    return
  end
  cmd(format('buffer %s', state.buffers[target_index].number))
end

function M.switch(args)
  local current_index = get_current_index()
  local target_index = get_target_index(args)
  if not target_index then
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
  components = componentz.setup(settings)
  augroups.setup(settings)
  mappings.setup()
  opt.showtabline = 2
  opt.tabline = '%!v:lua.cokeline()'
end

function _G.cokeline()
  state.buffers = buffers.get_listed(state.order)

  if settings.hide_when_one_buffer and #state.buffers == 1 then
    opt.showtabline = 0
    return
  end

  local lines = {}

  for _, buffer in pairs(state.buffers) do
    local line = {}

    for _, component in pairs(components) do
      local c = component:render(buffer)
      if c.text then
        insert(line, c.hlgroup:embed(c.text))
      end
    end

    line =
      fn.has('tablineat')
      and format('%%%s@cokeline#handle_click@%s', buffer.number, concat(line))
       or concat(line)

    insert(lines, line)
  end

  return concat(lines)
end

return M
