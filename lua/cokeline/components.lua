local Hlgroup = require("cokeline/hlgroups").Hlgroup

local rep = string.rep
local concat = table.concat
local insert = table.insert
local remove = table.remove

local fn = vim.fn
local map = vim.tbl_map

---@class Component
---@field index  number
---@field text  string|fun(buffer: Buffer): string
---@field style  string|fun(buffer:Buffer): string
---@field fg  string|fun(buffer:Buffer): string
---@field bg  string|fun(buffer:Buffer): string
---@field delete_buffer_on_left_click  boolean
---@field truncation  table
---@field idx  number
---@field bufnr  bufnr
---@field width  number
---@field hlgroup  Hlgroup
local Component = {}
Component.__index = Component

---@param c table
---@param i number
---@return Component
Component.new = function(c, i, default_hl)
  -- `default_hl` is `nil` when called by `components.lua#63`
  default_hl = default_hl or _G.cokeline.config.default_hl
  local component = {
    index = i,
    text = c.text,
    fg = c.fg or default_hl.fg or "NONE",
    bg = c.bg or default_hl.bg or "NONE",
    style = c.style or default_hl.style or "NONE",
    delete_buffer_on_left_click = c.delete_buffer_on_left_click or false,
    truncation = {
      priority = c.truncation and c.truncation.priority or i,
      direction = c.truncation and c.truncation.direction or "right",
    },
    -- These values aren't ready yet, they will be once the component gets
    -- rendered for a specific buffer.
    width = nil,
    bufnr = nil,
    hlgroup = nil,
  }
  setmetatable(component, Component)
  return component
end

-- Renders a component for a specific buffer.
---@param self   Component
---@param buffer Buffer
---@return Component
Component.render = function(self, buffer)
  local evaluate = function(field)
    return (type(field) == "string" and field)
      or (type(field) == "function" and field(buffer))
  end

  local component = vim.deepcopy(self)
  component.text = evaluate(self.text)
  component.width = fn.strwidth(component.text)
  component.bufnr = buffer.number

  -- `evaluate(self.hl.*)` might return `nil`, in that case we fallback to the
  -- default highlight first and to NONE if that's `nil` too.
  local style = evaluate(self.style)
    or evaluate(_G.cokeline.config.default_hl.style)
    or "NONE"
  local fg = evaluate(self.fg)
    or evaluate(_G.cokeline.config.default_hl.fg)
    or "NONE"
  local bg = evaluate(self.bg)
    or evaluate(_G.cokeline.config.default_hl.bg)
    or "NONE"

  component.hlgroup = Hlgroup.new(
    ("Cokeline_%s_%s"):format(buffer.number, self.index),
    style,
    fg,
    bg
  )

  return component
end

---@param self      Component
---@param to_width  number
---@param direction '"left"' | '"right"' | nil
Component.shorten = function(self, to_width, direction)
  -- If a direction is given that means we're cutting off a component that's
  -- at the edge of the bufferline (either the left or the right one). In this
  -- case we either prepend or append a space to the ellipses.
  --
  -- If a direction isn't given we're shortening a component within a buffer.
  -- Here we use that component's `truncation.direction`, and we don't add any
  -- additional spaces.
  if direction then
    local available_width = to_width - 2
    local start = direction == "left" and self.width - available_width or 0
    self.text = (direction == "left" and " …%s" or "%s… "):format(
      fn.strcharpart(self.text, start, available_width)
    )
  elseif self.truncation.direction == "middle" then
    local available_width = to_width - 1
    local width_left = math.floor(available_width / 2)
    local width_right = width_left + available_width % 2
    self.text = ("%s…%s"):format(
      fn.strcharpart(self.text, 0, width_left),
      fn.strcharpart(self.text, self.width - width_right, width_right)
    )
  else
    direction = self.truncation.direction
    local available_width = to_width - 1
    local start = direction == "left" and self.width - available_width or 0
    self.text = (direction == "left" and "…%s" or "%s…"):format(
      fn.strcharpart(self.text, start, available_width)
    )
  end

  -- `fn.strcharpart` can fail with wide characters. For example,
  -- `fn.strcharpart("｜", 0, 1)` will still return "｜" since that character
  -- takes up two columns. This is to handle such cases.
  if fn.strwidth(self.text) ~= to_width then
    local fmt = (direction == "left" and "%s…")
      or (direction == "right" and "…%s")
      or "%s "
    self.text = fmt:format(rep(" "), to_width - 1)
  end

  self.width = fn.strwidth(self.text)
end

-- Takes a list of components, returns a new list of components `to_width` wide
-- obtained by trimming the original `components` in the given `direction`.
---@param components Component[]
---@param to_width   number
---@param direction  '"left"' | '"right"' | nil
---@return Component[]
local shorten_components = function(components, to_width, direction)
  local current_width = 0
  for _, component in pairs(components) do
    current_width = current_width + component.width
  end

  -- `extra` is the width of the extra characters that are appended when a
  -- component is shortened, an ellipses if we're shortening within a buffer
  -- (in which case the `direction` is `nil`), or an ellipses and a space if
  -- we're cutting off a component at the edge of the bufferline (where
  -- `direction` is either `"left"` or `"right"`).
  local extra = direction and 2 or 1
  local i = direction == "left" and 1 or #components
  -- We start from the full list of components and remove components as
  -- necessary. We could start from an empty list and add until there's space,
  -- but I think there's usually more components to keep than to throw away, so
  -- this should be faster in most cases.
  local last_removed_component
  while
    (current_width > to_width)
    or (current_width - components[i].width + extra > to_width)
  do
    last_removed_component = remove(components, i)
    current_width = current_width - last_removed_component.width
    i = direction == "left" and 1 or i - 1
    if #components == 0 then
      break
    end
  end

  if to_width - current_width > extra or #components == 0 then
    i = direction == "left" and 1 or i + 1
    last_removed_component:shorten(to_width - current_width, direction)
    insert(components, i, last_removed_component)
  else
    -- Here we "shorten" a component to more than its current width.
    components[i]:shorten(
      components[i].width + to_width - current_width,
      direction
    )
  end

  return components
end

-- Takes in a list of components, returns the concatenation of their rendered
-- strings.
---@param components  Component[]
---@return string
local render_components = function(components)
  local embed = function(component)
    local text = component.hlgroup:embed(component.text)
    if not fn.has("tablineat") then
      return text
    else
      local on_click = component.delete_buffer_on_left_click
          and "CokelineHandleCloseButtonClick"
        or "CokelineHandleClick"
      return ("%%%s@%s@%s%%X"):format(component.bufnr, on_click, text)
    end
  end

  return concat(map(function(component)
    return embed(component)
  end, components))
end

---@param components  Component[]
---@return number
local width_of_components = function(components)
  local width = 0
  for _, component in pairs(components) do
    width = width + component.width
  end
  return width
end

return {
  Component = Component,
  render = render_components,
  shorten = shorten_components,
  width = width_of_components,
}
