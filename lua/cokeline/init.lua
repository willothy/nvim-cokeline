local defaults = require('cokeline/defaults')
local hlgroups = require('cokeline/hlgroups')
local augroups = require('cokeline/augroups')
local mappings = require('cokeline/mappings')
local buffers = require('cokeline/buffers')

local concat = table.concat
local insert = table.insert

local M = {}

local state = {
  buffers = {},
  order = {},
}

local function redraw()
  vim.cmd('redrawtabline')
  vim.cmd('redraw')
end

local function cokeline(settings)
  state.buffers = buffers.get_listed(state.order)

  if settings.hide_when_one_buffer and #state.buffers == 1 then
    vim.o.showtabline = 0
    return
  end

  local symbols = settings.symbols
  local titles = {}

  for _, buffer in pairs(state.buffers) do
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
      buffer:render_index()
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

-- FIXME
function M.toggle()
end

function M.focus()
end

function M.switch(args)
  local index_current
  for i, buffer in ipairs(state.buffers) do
    if args.bufnr == buffer.number then
      index_current = i
      break
    end
  end

  local index_target =
    args.target or index_current + args.step

  if index_target < 1 or index_target > #state.buffers then
    if args.strict_cycling then
      return
    else
      index_target = index_target % #state.buffers
    end
  end

  local buffer_current = state.buffers[index_current]
  local buffer_target = state.buffers[index_target]
  state.buffers[index_current] = buffer_target
  state.buffers[index_target] = buffer_current
  state.order = buffers.get_numbers(state.buffers)
  redraw()
end
--

function M.setup(preferences)
  local settings = defaults.merge(preferences)
  settings = hlgroups.setup(settings)
  augroups.setup(settings)
  mappings.setup(settings)
  _G.cokeline = function() return cokeline(settings) end
  vim.o.showtabline = 2
  vim.o.tabline = '%!v:lua.cokeline()'
end

return M
