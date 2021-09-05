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

local Line = {
  width = 0,
  buffer = nil,
  components = {},
}

function Line:new(buffer)
  local line = {}
  setmetatable(line, self)
  self.__index = self
  line.width = 0
  line.buffer = buffer
  line.components = {}
  return line
end

function Line:add_component(component)
  if component.text and component.text ~= '' then
    insert(self.components, component)
    self.width = self.width + component.width
  end
end

function Line:text()
  local text = concat(map(function(component)
    return component.hlgroup:embed(component.text)
  end, self.components))

  if fn.has('tablineat') then
    text = format('%%%s@cokeline#handle_click@%s', self.buffer.number, text)
  end

  return text
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
  local available_width = vim.o.columns
  local cokeline_width = 0
  local
    focused_buffer_column_start,
    focused_buffer_column_end,
    focused_buffer_width,
    focused_buffer_index

  for _, buffer in pairs(state.buffers) do
    local line = Line:new(buffer)
    for _, component in pairs(components) do
      line:add_component(component:render(buffer))
    end

    if buffer.is_focused then
      focused_buffer_column_start = cokeline_width + 1
      focused_buffer_column_end = focused_buffer_column_start + line.width
      focused_buffer_width = line.width
      focused_buffer_index = buffer.index
    end

    cokeline_width = cokeline_width + line.width
    insert(lines, line)
  end

  -- FROM HERE

  -- If there is enough space to show the whole bufferline, just concatenate
  -- all the lines and return them.
  if cokeline_width <= available_width then
    local cokeline = concat(map(function(line) return line:text() end, lines))
    return cokeline
  end

  -- If the end of the focused buffer is within the available width we include
  -- all the rest of the buffers that fit and cut the buffer that doesn't fit
  -- short appending an ellipsis.
  if focused_buffer_column_end <= available_width then
    local cutoff_buffer = ''
    -- From Lua 5.2 this will change to table.unpack
    lines = {unpack(lines, 1, focused_buffer_index)}
    cokeline_width = focused_buffer_column_end

    for _, buffer in pairs(state.buffers) do
      if buffer.index > focused_buffer_index then
        local line = Line:new(buffer)
        for _, component in pairs(components) do
          line:add_component(component:render(buffer))
        end

        if cokeline_width + line.width <= available_width then
          insert(lines, line)
          cokeline_width = cokeline_width + line.width
        else
          for _, c in ipairs(line.components) do
            if cokeline_width + c.width <= available_width then
              cutoff_buffer = cutoff_buffer .. c.hlgroup:embed(c.text)
              cokeline_width = cokeline_width + c.width
            else
              space_left = available_width - cokeline_width
              cutoff_component = c.text:sub(1, space_left) .. '…'
              cutoff_buffer = cutoff_buffer .. c.hlgroup:embed(cutoff_component)
              break
            end
          end
          if fn.has('tablineat') then
            cutoff_buffer = format('%%%s@cokeline#handle_click@%s', buffer.number, cutoff_buffer)
          end
          break
        end
      end
    end

    return concat(map(function(line) return line:text() end, lines)) .. cutoff_buffer
  end

  -- If the focused buffer is the buffer in between we ??
  if (focused_buffer_column_start <= available_width)
     and (focused_buffer_column_end >= available_width) then
  end

  -- If the focused buffer's start is beyoynd the available width we ??
  if focused_buffer_column_start > available_width then
  end

  -- If the focused buffer is wider than the available width we ??
  if focused_buffer_width > available_width then
  end

  return concat(map(function(line) return line:text() end, lines))

  -- TO HERE is all just spaghetti code for now
end

return M
