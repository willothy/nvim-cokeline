local deepcopy = require('cokeline/utils').deepcopy

local concat = table.concat
local insert = table.insert

local map = vim.tbl_map
local fn = vim.fn

local M = {}

M.Line = {}

function M.Line:new(buffer)
  local line = {
    width = 0,
    buffer = buffer,
    components = {},
    __components = {},
  }
  setmetatable(line, self)
  self.__index = self
  return line
end

function M.Line:add_component(component)
  if not component.text or component.text == '' then
    return
  end
  self.width = self.width + component.width
  insert(self.components, component)
  insert(self.__components, deepcopy(component))
end

-- function M.Line:expand(args)
--   local padding = 'a'
-- end

function M.Line:shorten(args)
  local empty_fmt, components
  if args.direction then
    components = self.__components
    empty_fmt = components[1].cutoff_fmt[args.direction]:format('')
    -- If we're cutting from left to right reverse the order of the components.
    if args.direction == 'left' then
      table.sort(components, function(c1, c2) return c1.index > c2.index end)
    end
  else
    components = self.components
    local trunc_direction = components[1].truncation.direction
    empty_fmt = components[1].truncation_fmt[trunc_direction]:format('')
    -- Sort components in order of "decreasing" (actually increasing) priority.
    table.sort(components, function(c1, c2)
      return c1.truncation.priority < c2.truncation.priority
    end)
  end

  local remaining_space = args.available_space
  local subcomponents = {}

  for i, component in ipairs(components) do
    if remaining_space > component.width then
      insert(subcomponents, component)
      remaining_space = remaining_space - component.width
      -- If we're adding the last component and there's still space left that
      -- means args.available_space was bigger than self.width.
      -- We "shorten" the last component to its width plus the remaining space.
      if i == #components and remaining_space > 0 then
        subcomponents[i]:shorten({
          direction = args.direction,
          available_space = subcomponents[i].width + remaining_space,
        })
      end
    else
      -- If the remaining space is less than the width of the component's empty
      -- shortened format we shorten the previous component.
      if remaining_space < fn.strwidth(empty_fmt) then
        subcomponents[i - 1]:shorten({
          direction = args.direction,
          available_space = subcomponents[i - 1].width + remaining_space,
        })
        break
      end
      component:shorten({
        direction = args.direction,
        available_space = remaining_space,
      })
      insert(subcomponents, component)
      break
    end
  end

  -- Reorder components in order of increasing index.
  table.sort(subcomponents, function(c1, c2) return c1.index < c2.index end)

  local line = M.Line:new(self.buffer)
  line.width = args.available_space
  line.components = subcomponents
  line.__components = self.__components

  return line
end

function M.Line:render()
  local text = concat(map(function(component)
    return component.hlgroup:embed(component.text)
  end, self.components))

  if fn.has('tablineat') then
    text = ('%%%s@cokeline#handle_click@%s'):format(self.buffer.number, text)
  end

  return text
end

return M
