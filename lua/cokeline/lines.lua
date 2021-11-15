local concat = table.concat
local insert = table.insert
local sort = table.sort

local map = vim.tbl_map
local fn = vim.fn

local M = {}

M.Line = {}

function M.Line:new(buffer)
  local line = {
    width = 0,
    buffer = buffer,
    components = {},
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
end

function M.Line:shorten(args)
  local components = {}
  local remaining_space = args.available_space

  for i, component in ipairs(self.components) do
    if remaining_space > component.width then
      insert(components, component)
      remaining_space = remaining_space - component.width
      -- If we're adding the last component and there's still space left that
      -- means args.available_space was bigger than self.width.
      -- We "shorten" the last component to its width plus the remaining space.
      if i == #self.components and remaining_space > 0 then
        components[i]:shorten({
          direction = args.direction,
          available_space = components[i].width + remaining_space,
        })
      end
    else
      -- If the remaining space is less than the width of the continuation
      -- indicator (either a single ellipses or an ellipses and a space) we
      -- shorten the previous component.
      if remaining_space < args.continuation_fmt_width then
        local j = (i == 1) and 1 or i - 1
        components[j]:shorten({
          direction = args.direction,
          available_space = self.components[j].width + remaining_space,
        })
        break
      end
      component:shorten({
        direction = args.direction,
        available_space = remaining_space,
      })
      insert(components, component)
      break
    end
  end

  -- Reorder rendered components in order of increasing index.
  sort(components, function(c1, c2) return c1.index < c2.index end)

  self.components = components
  self.width = args.available_space
end

function M.Line:truncate(args)
  -- Sort components in order of decreasing (technically increasing) priority.
  sort(self.components, function(c1, c2)
    return c1.truncation.priority < c2.truncation.priority
  end)

  self:shorten({
    direction = nil,
    available_space = args.available_space,
    continuation_fmt_width = 1 -- 1 = strwidth('…')
  })
end

function M.Line:cutoff(args)
  -- If we're cutting from left to right reverse the order of the components.
  if args.direction == 'left' then
    sort(self.components, function(c1, c2) return c1.index > c2.index end)
  end

  self:shorten({
    direction = args.direction,
    available_space = args.available_space,
    continuation_fmt_width = 2, -- 2 = strwidth(' …') = strwidth('… ')
  })
end

-- function M.Line:expand(args)
--   local padding = 'a'
-- end

function M.Line:render()
  local line_text = concat(map(function(component)
    local component_text =
      (component.delete_buffer_on_left_click and fn.has('tablineat'))
      and component:embed_text_in_close_button_fmt(self.buffer.number)
       or component.text

    return component.hlgroup:embed(component_text)
  end, self.components))

  return
    fn.has('tablineat')
    and ('%%%s@cokeline#handle_click@%s'):format(self.buffer.number, line_text)
     or line_text
end

return M
