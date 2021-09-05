local Hlgroup = require('cokeline/hlgroups').Hlgroup

local format = string.format
local insert = table.insert

local fn = vim.fn

local M = {}

M.Component = {
  text = '',
  hl = nil,
  delete_buffer_on_left_click = false,

  hlgroup = nil,
  width = 0,
  default_hlgroup = {
    focused = nil,
    unfocused = nil,
  },
}

local evaluate_field = function(field, buffer)
  if type(field) == 'string' then
   return field
  elseif type(field) == 'function' then
    return field(buffer)
  end
end

function M.Component:new(raw_component, index, settings)
  local component = {}
  setmetatable(component, self)
  self.__index = self

  component.text = raw_component.text
  component.hl = raw_component.hl
  component.delete_buffer_on_left_click = raw_component.delete_buffer_on_left_click

  component.index = index

  component.default_hlgroup.focused = Hlgroup:new({
    name = 'CokeFocused',
    opts = {
      guifg = settings.focused_fg,
      guibg = settings.focused_bg,
    }
  })

  component.default_hlgroup.unfocused = Hlgroup:new({
    name = 'CokeUnfocused',
    opts = {
      guifg = settings.unfocused_fg,
      guibg = settings.unfocused_bg,
    }
  })

  return component
end

function M.Component:render(buffer)
  local c = {}
  setmetatable(c, self)
  self.__index = self

  c.text = evaluate_field(self.text, buffer)
  c.width = fn.strwidth(c.text)

  if self.delete_buffer_on_left_click and fn.has('tablineat') then
    c.text = format(
      '%%%s@cokeline#close_button_handle_click@%s%%%s@cokeline#handle_click@',
      buffer.number,
      c.text,
      buffer.number
    )
  end

  c.hlgroup =
    buffer.is_focused
    and self.default_hlgroup.focused
     or self.default_hlgroup.unfocused

  if self.hl then
    local gui =
      self.hl.style
      and evaluate_field(self.hl.style, buffer)
       or c.hlgroup.opts.gui

    local guifg =
      self.hl.fg
      and evaluate_field(self.hl.fg, buffer)
       or c.hlgroup.opts.guifg

    local guibg =
      self.hl.bg
      and evaluate_field(self.hl.bg, buffer)
       or c.hlgroup.opts.guibg

    c.hlgroup = Hlgroup:new({
      name = format('%s%s_%s', c.hlgroup.name, buffer.number, self.index),
      opts = {
        gui = gui,
        guifg = guifg,
        guibg = guibg,
      }
    })
  end

  return c
end

function M.setup(settings)
  local raw_components = settings.components
  local components = {}

  for index, raw_component in ipairs(raw_components) do
    insert(components, M.Component:new(raw_component, index, settings))
  end

  return components
end

return M
