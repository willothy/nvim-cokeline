local sliders = require('cokeline/sliders')
local DefaultSlider = sliders.CenterFocusedSlider

local concat = table.concat
local insert = table.insert
local remove = table.remove

local map = vim.tbl_map
local opt = vim.opt

local focused_index
-- local in_view

local M = {}

M.View = {}

function M.View:new(settings)
  local view = {
    lines = {
      focused = nil,
      left = {},
      right = {},
    },
    min_line_width = settings.min_line_width or 0,
    max_line_width = settings.max_line_width or 999,
    slider =
      settings.slider
      and settings.slider:new()
       or DefaultSlider:new(),
  }
  setmetatable(view, self)
  self.__index = self
  return view
end

function M.View:add_line(line)
  if line.width < self.min_line_width then
    line:expand({available_space = self.min_line_width})
  elseif line.width > self.max_line_width then
    line:truncate({available_space = self.max_line_width})
  end

  if line.buffer.is_focused then
    focused_index = line.buffer.index
    self.lines.focused = line
    return
  end

  if not self.lines.focused then
    insert(self.lines.left, line)
    self.slider.widths.left = self.slider.widths.left + line.width
  else
    insert(self.lines.right, line)
    self.slider.widths.right = self.slider.widths.right + line.width
  end
end

function M.View:update_focused_line()
  -- 3 buffers, first 2 are visible, last one isn't. We focus the last buffer,
  -- then the 2nd, then close the 2nd. Without this check `focused_index` would
  -- still be 2.
  local lines = self.lines.left
  while not lines[focused_index] do
    focused_index = focused_index - 1
  end

  self.lines.focused = remove(lines, focused_index)
  self.slider.widths.left = self.slider.widths.left - self.lines.focused.width

  for _=0,(#lines - focused_index) do
    local line = remove(self.lines.left, focused_index)
    insert(self.lines.right, line)
    self.slider.widths.left = self.slider.widths.left - line.width
    self.slider.widths.right = self.slider.widths.right + line.width
  end
end

function M.View:render_lines(args)
  local lines_2_render
  if args.direction == 'right' then
    lines_2_render = self.lines.right
  elseif args.direction == 'left' then
    lines_2_render = self.lines.left
    table.sort(lines_2_render, function(l1, l2)
      return l1.buffer.index > l2.buffer.index
    end)
  end

  local lines = {}
  local remaining_space = args.available_space
  local continuation_indicator_width = 2

  for i, line in ipairs(lines_2_render) do
    if (line.width < remaining_space)
        or (line.width == remaining_space and i == #lines_2_render) then
      insert(lines, line)
      remaining_space = remaining_space - line.width
    else
      -- If the remaining space is less than the width of an ellipses and a
      -- space we "cutoff" either the previous line or the focused line to its
      -- width plus the remaining space.
      if remaining_space < continuation_indicator_width then
        line = (i == 1) and self.lines.focused or lines[i - 1]
        line:cutoff({
          direction = args.direction,
          available_space =
            math.min(line.width + remaining_space, opt.columns._value),
        })
        break
      end
      line:cutoff({
        direction = args.direction,
        available_space = remaining_space,
      })
      insert(lines, line)
      break
    end
  end

  if args.direction == 'left' then
    table.sort(lines, function(l1, l2)
      return l1.buffer.index < l2.buffer.index
    end)
  end

  return concat(map(function(line) return line:render() end, lines))
end

function M.View:render()
  if not self.lines.focused then
    self:update_focused_line()
  end

  local available_space = opt.columns._value
  available_space = math.max(available_space - self.lines.focused.width, 0)

  local spaces = self.slider:compute_spaces(available_space)

  local left = self:render_lines({
    direction = 'left',
    available_space = spaces.left,
  })

  local right = self:render_lines({
    direction = 'right',
    available_space = spaces.right,
  })

  return left .. self.lines.focused:render() .. right
end

return M
