local defaults = require('cokeline/defaults')
local hlgroups = require('cokeline/hlgroups')
local augroups = require('cokeline/augroups')
local mappings = require('cokeline/mappings')
local buffers = require('cokeline/buffers')

local format = string.format
local concat = table.concat
local insert = table.insert

local map = vim.tbl_map
local cmd = vim.cmd
local opt = vim.opt
local fn = vim.fn

local M = {}

local settings = {}

local state = {
  buffers = {},
  order = {},
}

local function get_current_index()
  current_buffer_number = fn.bufnr('%')
  for index, buffer in ipairs(state.buffers) do
    if current_buffer_number == buffer.number then
      return index
    end
  end
end

local function get_target_index(args)
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

local function redraw()
  cmd('redrawtabline')
  cmd('redraw')
end

function _G.cokeline()
  state.buffers = buffers.get_listed(state.order)

  if settings.hide_when_one_buffer and #state.buffers == 1 then
    opt.showtabline = 0
    return
  end

  local symbols = settings.symbols
  local titles = {}

  for index, buffer in ipairs(state.buffers) do
    local hlgroups =
      buffer.is_focused
      and settings.hlgroups.focused
       or settings.hlgroups.unfocused

    buffer.title = hlgroups.title:embed(settings.line_format)

    if settings.handle_clicks then
      buffer:embed_in_clickable_region()
    end
    if settings.show_devicons then
      buffer:render_devicon(hlgroups.devicons)
    end
    if settings.show_indexes then
      buffer:render_index(index)
    end
    if settings.show_flags then
      buffer:render_flags(
        symbols.modified,
        symbols.readonly,
        hlgroups.modified,
        hlgroups.readonly,
        settings.flags_format,
        hlgroups.title:embed(settings.flags_divider))
    end
    if settings.show_close_buttons then
      buffer:render_close_button(symbols.close_button)
    end
    if settings.show_filenames then
      buffer:render_filename()
    end
    insert(titles, buffer.title)
  end

  return concat(titles)
end

function M.toggle()
  opt.showtabline = #fn.getbufinfo({buflisted = 1}) > 1 and 2 or 0
end

function M.focus(args)
  local target_index = get_target_index(args)
  if target_index == nil then
    return
  end
  cmd(format('buffer %s', state.buffers[target_index].number))
end

function M.switch(args)
  local current_index = get_current_index()
  local target_index = get_target_index(args)
  if target_index == nil then
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
  settings = hlgroups.setup(settings)
  augroups.setup(settings)
  mappings.setup()
  opt.showtabline = 2
  opt.tabline = '%!v:lua.cokeline()'
end

return M
