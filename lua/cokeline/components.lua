local hlgroups = require('cokeline/hlgroups')

local strrep = string.rep
local insert = table.insert

local fn = vim.fn

local M = {}

local evaluate_field = function(field, buffer)
  if type(field) == 'string' then
    return field
  elseif type(field) == 'function' then
    return field(buffer)
  end
end

M.Component = {}

function M.Component:new(c, index)
  local component = {
    -- Exposed to users
    text = c.text,
    hl = c.hl,
    delete_buffer_on_left_click = c.delete_buffer_on_left_click,
    truncation = {
      priority = c.truncation and c.truncation.priority or index,
      direction = c.truncation and c.truncation.direction or 'right',
    },
    -- Used internally
    index = index,
    width = 0,
    hlgroup = nil,
  }
  setmetatable(component, self)
  self.__index = self
  return component
end

function M.Component:embed_text_in_close_button_fmt(bufnr)
  local fmt =
    '%%%s@cokeline#handle_close_button_click@%s%%%s@cokeline#handle_click@'
  return fmt:format(bufnr, self.text, bufnr)
end

function M.Component:render(buffer)
  local component = {}
  setmetatable(component, self)
  self.__index = self

  component.text = evaluate_field(self.text, buffer)
  component.width = fn.strwidth(component.text)

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

    component.hlgroup = hlgroups.Hlgroup:new({
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
  local direction, continuation_fmt, continuation_fmt_width
  if args.direction then
    -- If the direction is given this was called from a line:cutoff()
    direction = args.direction
    continuation_fmt = (direction == 'left') and ' …%s' or '%s… '
    continuation_fmt_width = 2 -- 2 = strwidth(' …') = strwidth('… ')
  else
    -- If it isn't it was called from a line:truncate()
    direction = self.truncation.direction
    continuation_fmt = (direction == 'left') and '…%s' or '%s…'
    continuation_fmt_width = 1 -- 1 = strwidth('…')
  end

  local available_space = args.available_space - continuation_fmt_width
  local start_char = direction == 'right' and 0 or self.width - available_space

  -- `fn.strcharpart` can fail with wide characters. For example,
  -- `fn.strcharpart('｜', 0, 1)` will still return '｜' since that character
  -- takes up two columns. The last `if` is to handle such cases.
  local shortened_text = fn.strcharpart(self.text, start_char, available_space)
  self.text = continuation_fmt:format(shortened_text)
  self.width = fn.strwidth(self.text)

  -- If for whatever reason it wasn't possible to shorten the component's width
  -- down to the available space, we set its text equal to the empty
  -- continuation format padded with however many spaces we need to fill the
  -- remaining space.
  if self.width ~= args.available_space then
    local spaces = strrep(' ', args.available_space - continuation_fmt_width)
    self.text =
      direction == 'right'
      and continuation_fmt:format('') .. spaces
       or spaces .. continuation_fmt:format('')
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
