local utils = require('cokeline/utils')

local concat = table.concat
local insert = table.insert
local format = string.format

local map = vim.tbl_map
local fn = vim.fn

local M = {}

M.Line = {
  width = 0,
  buffer = nil,
  components = {},
  __components = {},
}

function M.Line:new(buffer)
  local line = {}
  setmetatable(line, self)
  self.__index = self
  line.width = 0
  line.buffer = buffer
  line.components = {}
  line.__components = {}
  return line
end

function M.Line:add_component(component)
  if component.text and component.text ~= '' then
    self.width = self.width + component.width
    insert(self.components, component)
    insert(self.__components, utils.deepcopy(component))
  end
end

function M.Line:expand(args)
  local padding = 'a'
end

-- TODO: abstract away the common parts between truncate and cutoff.

function M.Line:truncate(args)
  local components = self.components
  local remaining_space = args.available_space
  local subcomponents = {}

  -- Reorder components in order of "decreasing" (actually increasing)
  -- priority.
  table.sort(components, function(c1, c2)
    return c1.truncation.priority < c2.truncation.priority
  end)

  for i, component in ipairs(components) do
    if remaining_space > component.width then
      insert(subcomponents, component)
      remaining_space = remaining_space - component.width
      -- If we're adding the last component and there's still space left that
      -- means args.available_space was bigger than self.width.
      -- We "shorten" the last component to its width plus the remaining space.
      if i == #components and remaining_space > 0 then
        subcomponents[i]:truncate({
          available_space = subcomponents[i].width + remaining_space,
        })
      end
    else
      -- If the remaining space is less than the width of the truncation format
      -- we truncate the previous component.
      -- TODO: this is some serious spaghetti code, refactor!
      local empty_truncation =
        component.truncation_fmt[component.truncation.direction]:format('')
      if remaining_space < fn.strwidth(empty_truncation) then
        subcomponents[i - 1]:truncate({
          available_space = subcomponents[i - 1].width + remaining_space,
        })
        break
      end
      component:truncate({available_space = remaining_space})
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

function M.Line:cutoff(args)
  local components =
    (args.direction == 'right')
    and self.__components
     or utils.reverse(self.__components)

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
        subcomponents[i]:cutoff({
          direction = args.direction,
          available_space = subcomponents[i].width + remaining_space,
        })
      end
    else
      -- If the remaining space is less than the width of the cutoff format we
      -- cutoff the previous component.
      -- TODO: this is some serious spaghetti code, refactor!
      local empty_cutoff = component.cutoff_fmt[args.direction]:format('')
      if remaining_space < fn.strwidth(empty_cutoff) then
        subcomponents[i - 1]:cutoff({
          direction = args.direction,
          available_space = subcomponents[i - 1].width + remaining_space,
        })
        break
      end
      component:cutoff({
        direction = args.direction,
        available_space = remaining_space,
      })
      insert(subcomponents, component)
      break
    end
  end

  if args.direction == 'left' then
    subcomponents = utils.reverse(subcomponents)
  end

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
    text = format('%%%s@cokeline#handle_click@%s', self.buffer.number, text)
  end

  return text
end

return M
