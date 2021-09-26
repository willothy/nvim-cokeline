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
}

function M.Line:new(buffer)
  local line = {}
  setmetatable(line, self)
  self.__index = self
  line.width = 0
  line.buffer = buffer
  line.components = {}
  return line
end

function M.Line:add_component(component, direction)
  local insert_component =
    (direction == 'left')
    and function(c) insert(self.components, 1, c) end
     or function(c) insert(self.components, c) end

  if component.text and component.text ~= '' then
    self.width = self.width + component.width
    insert_component(component)
  end
end

function M.Line:cutoff(args)
  local components =
    args.direction == 'right'
    and self.components
     or utils.reverse(self.components)

  self.components = {}

  local remaining_space = args.available_space

  -- TODO: lines 66-90 and 96-120 are identical. The code can't be put inside a
  -- function because it includes 'break's for the outer for loop. We could
  -- still put it into a function, return a boolean at that points and check
  -- for the value of the boolean but that's not elegant. There has to be a
  -- more expressive way.

  for i, component in ipairs(components) do
    if component.width < remaining_space then
      self:add_component(component, args.direction)
      remaining_space = remaining_space - component.width

    elseif component.width == remaining_space then
      -- If the component exactly fills the remaining space we check if is the
      -- last one. If it isn't we shorten it to its width.
      if next(components, i) then
        -- If the remaining space is less than the width of the cutoff format
        -- we cutoff the previous component.
        if remaining_space
            < fn.strwidth(component.cutoff_fmt[args.direction]:format('')) then
          -- If this is the first component in the line, we set its text to
          -- blank spaces, add it to the line and break early.
          if i == 1 then
            component.text = string.rep(' ', remaining_space)
            component.width = fn.strwidth(component.text)
            self.add_component(component, args.direction)
            break
          end

          local j = (args.direction == 'right') and (i - 1) or 1
          self.components[j]:cutoff({
            direction = args.direction,
            available_space = remaining_space + self.components[j].width,
          })
          break
        end

        component:cutoff({
          direction = args.direction,
          available_space = component.width,
        })
      end
      self:add_component(component, args.direction)
      break

    else
      -- If the remaining space is less than the width of the cutoff format we
      -- cutoff the previous component.
      if remaining_space
          < fn.strwidth(component.cutoff_fmt[args.direction]:format('')) then
        -- If this is the first component in the line, we set its text to blank
        -- spaces, add it to the line and break early.
        if i == 1 then
          component.text = string.rep(' ', remaining_space)
          component.width = fn.strwidth(component.text)
          self.add_component(component, args.direction)
          break
        end

        local j = (args.direction == 'right') and (i - 1) or 1
        self.components[j]:cutoff({
          direction = args.direction,
          available_space = remaining_space + self.components[j].width,
        })
        break
      end

      component:cutoff({
        direction = args.direction,
        available_space = remaining_space,
      })
      self:add_component(component, args.direction)
      break
    end
  end
end

function M.Line:text()
  local text = concat(map(
    function(component) return component.hlgroup:embed(component.text) end,
    self.components
  ))

  if fn.has('tablineat') then
    text = format('%%%s@cokeline#handle_click@%s', self.buffer.number, text)
  end

  return text
end

return M
