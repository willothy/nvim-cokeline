local hlgroups = require('cokeline/hlgroups')
local Hlgroup = hlgroups.Hlgroup

local strrep = string.rep
local insert = table.insert

local fn = vim.fn

local M = {}

M.Component = {}

local evaluate_field = function(field, buffer)
  if type(field) == 'string' then
    return field
  elseif type(field) == 'function' then
    return field(buffer)
  end
end

function M.Component:new(c, index)
  local component = {
    -- Exposed to users
    text = c.text,
    hl = c.hl,
    delete_buffer_on_left_click = c.delete_buffer_on_left_click,
    truncation = {
      priority = index,
      direction = 'right',
    },
    -- Used internally
    index = index,
    width = 0,
    hlgroup = nil,
    truncation_fmt = {
      left = '…%s',
      right = '%s…',
    },
    cutoff_fmt = {
      left = ' …%s',
      right = '%s… ',
    },
  }
  setmetatable(component, self)
  self.__index = self

  if c.truncation then
    component.truncation = {
      priority = c.truncation.priority or index,
      direction = c.truncation.direction or 'right',
    }
  end

  return component
end

function M.Component:render(buffer)
  local component = {}
  setmetatable(component, self)
  self.__index = self

  component.text = evaluate_field(self.text, buffer)
  component.width = fn.strwidth(component.text)

  if self.delete_buffer_on_left_click and fn.has('tablineat') then
    local fmt =
      '%%%s@cokeline#close_button_handle_click@%s%%%s@cokeline#handle_click@'
    component.text = fmt:format(buffer.number, component.text, buffer.number)
  end

  component.hlgroup =
    buffer.is_focused
    and hlgroups.defaults.focused
     or hlgroups.defaults.unfocused

  if self.hl then
    local gui =
      self.hl.style
      and evaluate_field(self.hl.style, buffer)
       or component.hlgroup.opts.gui

    local guifg =
      self.hl.fg
      and evaluate_field(self.hl.fg, buffer)
       or component.hlgroup.opts.guifg

    local guibg =
      self.hl.bg
      and evaluate_field(self.hl.bg, buffer)
       or component.hlgroup.opts.guibg

    component.hlgroup = Hlgroup:new({
      name =
        ('%s%s_%s'):format(component.hlgroup.name, buffer.number, self.index),
      opts = {
        gui = gui,
        guifg = guifg,
        guibg = guibg,
      }
    })
  end

  return component
end

function M.Component:shorten(args)
  local direction, shortened_fmt
  if args.direction then
    direction = args.direction
    shortened_fmt = self.cutoff_fmt[direction]
  else
    direction = self.truncation.direction
    shortened_fmt = self.truncation_fmt[direction]
  end

  local empty_fmt = shortened_fmt:format('')
  local available_space = args.available_space - fn.strwidth(empty_fmt)
  local start_char =
    (direction == 'right') and 0 or (fn.strwidth(self.text) - available_space)

  -- `fn.strcharpart` can fail with wide characters. For example,
  -- `fn.strcharpart('｜', 0, 1)` will still return '｜' since that character
  -- takes up two columns. The last `if` is to handle such cases.
  local shortened_text = fn.strcharpart(self.text, start_char, available_space)
  self.text = shortened_fmt:format(shortened_text)
  self.width = fn.strwidth(self.text)

  -- If it wasn't possible to shorten the component's width down to the
  -- available space, we just set its text equal to the empty shortened format
  -- padded with however many spaces we need to fill the remaining space.
  if self.width ~= args.available_space then
    local spaces = strrep(' ', args.available_space - fn.strwidth(empty_fmt))
    self.text =
      (direction == 'right') and (empty_fmt .. spaces) or (spaces .. empty_fmt)
    self.width = fn.strwidth(self.text)
  end
end

function M.setup(settings)
  local components = {}
  for index, c in ipairs(settings) do
    insert(components, M.Component:new(c, index))
  end
  return components
end

return M
