local Hlgroup = require('cokeline/hlgroups').Hlgroup

local format = string.format
local insert = table.insert

local fn = vim.fn

local M = {}

local default_hl = {}

M.Component = {
  text = '',
  hl = nil,
  delete_buffer_on_left_click = false,

  index = 0,
  width = 0,

  hlgroup = nil,
  default_hlgroup = {
    focused = nil,
    unfocused = nil,
  },

  cutoff_fmt = {
    left = ' …%s',
    right = '%s… ',
  }
}

local evaluate_field = function(field, buffer)
  if type(field) == 'string' then
   return field
  elseif type(field) == 'function' then
    return field(buffer)
  end
end

function M.Component:new(c, index)
  local component = {}
  setmetatable(component, self)
  self.__index = self

  component.text = c.text
  component.hl = c.hl
  component.delete_buffer_on_left_click = c.delete_buffer_on_left_click

  component.index = index

  component.default_hlgroup.focused = Hlgroup:new({
    name = 'CokeFocused',
    opts = {
      guifg = default_hl.focused.fg,
      guibg = default_hl.focused.bg,
    }
  })

  component.default_hlgroup.unfocused = Hlgroup:new({
    name = 'CokeUnfocused',
    opts = {
      guifg = default_hl.unfocused.fg,
      guibg = default_hl.unfocused.bg,
    }
  })

  return component
end

function M.Component:render(buffer)
  local component = {}
  setmetatable(component, self)
  self.__index = self

  component.text = evaluate_field(self.text, buffer)
  component.width = fn.strwidth(component.text)

  if self.delete_buffer_on_left_click and fn.has('tablineat') then
    component.text = format(
      '%%%s@cokeline#close_button_handle_click@%s%%%s@cokeline#handle_click@',
      buffer.number,
      component.text,
      buffer.number
    )
  end

  component.hlgroup =
    buffer.is_focused
    and self.default_hlgroup.focused
     or self.default_hlgroup.unfocused

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
        format('%s%s_%s', component.hlgroup.name, buffer.number, self.index),
      opts = {
        gui = gui,
        guifg = guifg,
        guibg = guibg,
      }
    })
  end

  return component
end

function M.Component:cutoff(args)
  self.width = args.available_space

  local available_space =
    args.available_space
    - fn.strwidth(self.cutoff_fmt[args.direction]:format(''))

  local start =
    args.direction == 'left'
    and fn.strwidth(self.text) - available_space
     or 0

  self.text =
    self.cutoff_fmt[args.direction]:format(
      fn.strcharpart(self.text, start, available_space)
    )
end

function M.setup(settings)
  default_hl = settings.default_hl
  local components = {}
  for index, c in ipairs(settings.components) do
    insert(components, M.Component:new(c, index))
  end
  return components
end

return M
