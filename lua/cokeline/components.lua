local Hlgroup = require('cokeline/hlgroups').Hlgroup

local format = string.format

local fn = vim.fn

local M = {}

M.Component = {
  text = '',
  condition = false,
  hlgroup = {
    fg = '',
    bg = '',
    style = '',
  },
  on_click = nil,
  width = 0,
}

local evaluate_field = function(field, buffer)
  if type(field) == 'string' then
    return field
  elseif type(field) == 'function' then
    return field(buffer)
  end
end

function M.Component:new(raw_component, buffer, index)
  -- TODO
  -- assert that raw_component.text exists and is either a string or a function
  -- print an error msg if assertion fails

  local component = {}
  setmetatable(component, self)
  self.__index = self

  -- TODO
  local default_fg =
    buffer.is_focused
    and '#3b4252'
     or '#d8dee9'
  local default_bg =
    buffer.is_focused
    and '#d8dee9'
     or '#3b4252'
  --

  component.text = evaluate_field(raw_component.text, buffer)
  component.width = fn.strwidth(component.text)

  local gui, guifg, guibg

  if raw_component.hl then
    gui =
      raw_component.hl.style
      and evaluate_field(raw_component.hl.style, buffer)
       or nil
    guifg =
      raw_component.hl.fg
      and evaluate_field(raw_component.hl.fg, buffer)
       or default_fg
    guibg =
      raw_component.hl.bg
      and evaluate_field(raw_component.hl.bg, buffer)
       or default_bg
  else
    guifg = default_fg
    guibg = default_bg
  end

  component.hlgroup = Hlgroup:new({
    name = format('Coke%socused%s%s',
                  buffer.is_focused and 'F' or 'Unf',
                  buffer.number,
                  index),
    opts = {
      gui = gui,
      guifg = guifg,
      guibg = guibg,
    }
  })

  if raw_component.delete_buffer_on_left_click then
    component.text = format(
      '%%%s@cokeline#close_button_handle_click@%s%%%s@cokeline#handle_click@',
      buffer.number,
      component.text,
      buffer.number
    )
  end

  return component
end

return M
