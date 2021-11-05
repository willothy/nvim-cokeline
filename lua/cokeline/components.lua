local hlgroups = require('cokeline/hlgroups')
local Hlgroup = hlgroups.Hlgroup

local insert = table.insert

local fn = vim.fn

local M = {}

M.Component = {
  -- Exposed to users
  text = '',
  hl = nil,
  delete_buffer_on_left_click = false,
  truncation = {
    priority = 0,
    direction = 'right',
  },

  -- Used internally
  index = 0,
  width = 0,
  hlgroup = nil,
  truncation_fmt = {
    left = '…%s',
    right = '%s…',
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

  component.index = index
  component.text = c.text
  component.hl = c.hl
  component.delete_buffer_on_left_click = c.delete_buffer_on_left_click
  if c.truncation then
    component.truncation = {
      priority = c.truncation.priority or index,
      direction = c.truncation.direction or 'right',
    }
  else
    component.truncation = {
      priority = index,
      direction = 'right',
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

-- TODO: abstract away the common parts between truncate and cutoff.

function M.Component:truncate(args)
  local direction = self.truncation.direction
  local empty_truncation = self.truncation_fmt[direction]:format('')
  local available_space = args.available_space - fn.strwidth(empty_truncation)

  local start =
    direction == 'left'
    and (fn.strwidth(self.text) - available_space)
     or 0

  -- fn.strcharpart can fail with wide characters. For example,
  -- fn.strcharpart('｜', 0, 1) will still return '｜' since that character
  -- takes up two columns. The last if is for cases like that.
  self.text =
    self.truncation_fmt[direction]:format(
      fn.strcharpart(self.text, start, available_space)
    )

  self.width = fn.strwidth(self.text)

  -- If it wasn't possible to truncate the component's width down to the
  -- available space, we just set the text equal to the empty truncation format
  -- plus however many spaces we need to fill the remaining space.
  if self.width ~= args.available_space then
    local spaces =
      string.rep(' ', args.available_space - fn.strwidth(empty_truncation))
    self.text =
      direction == 'left'
       and (spaces .. empty_truncation)
        or (empty_truncation .. spaces)
  end
end

function M.Component:cutoff(args)
  local direction = args.direction or self.truncation.direction
  local empty_cutoff = self.cutoff_fmt[direction]:format('')
  local available_space = args.available_space - fn.strwidth(empty_cutoff)

  local start =
    args.direction == 'left'
    and (fn.strwidth(self.text) - available_space)
     or 0

  -- fn.strcharpart can fail with wide characters. For example,
  -- fn.strcharpart('｜', 0, 1) will still return '｜' since that character
  -- takes up two columns. The last if is for cases like that.
  self.text =
    self.cutoff_fmt[args.direction]:format(
      fn.strcharpart(self.text, start, available_space)
    )

  self.width = fn.strwidth(self.text)

  -- If it wasn't possible to cutoff the component's width down to the
  -- available space, we just set the text equal to the empty cutoff format
  -- plus however many spaces we need to fill the remaining space.
  if self.width ~= args.available_space then
    local spaces =
      string.rep(' ', args.available_space - fn.strwidth(empty_cutoff))
    self.text =
      args.direction == 'left'
       and (spaces .. empty_cutoff)
        or (empty_cutoff .. spaces)
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
