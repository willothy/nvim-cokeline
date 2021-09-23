local utils = require('cokeline/utils')

local insert = table.insert
local format = string.format

local M = {}

M.Line = {
  text = '',
  width = 0,
  buffer = nil,
  components = {},
}

function M.Line:new(buffer)
  local line = {}
  setmetatable(line, self)
  self.__index = self
  line.text = ''
  line.width = 0
  line.buffer = buffer
  line.components = {}
  return line
end

function M.Line:add_component(component)
  if component.text and component.text ~= '' then
    self.text = self.text .. component.hlgroup:embed(component.text)
    self.width = self.width + component.width
    insert(self.components, component)
  end
end

function M.Line:shorten(args)
  self.text = ''
  self.width = 0
  local join

  if args.direction == 'right' then
    join = function(a, b) return a .. b end
  elseif args.direction == 'left' then
    join = function(a, b) return b .. a end
    self.components = utils.reverse(self.components)
  end

  for _, component in ipairs(self.components) do
    if self.width + component.width < args.available_space then
      self.text = join(self.text, component.hlgroup:embed(component.text))
      self.width = self.width + component.width

    elseif self.width + component.width == args.available_space then
      if not next(self.components, _) then
        self.text = join(self.text, component.hlgroup:embed(component.text))
      else
        component:shorten({
          direction = args.direction,
          available_space = component.width,
        })
        self.text = join(self.text, component.hlgroup:embed(component.text))
        break
        -- check if this is the last component. If it is then ok, if it isn't
        -- we should do something because then the next component will have 0
        -- available space and bad things happen.
      end

    else
      component:shorten({
        direction = args.direction,
        available_space = args.available_space - self.width,
      })
      self.text = join(self.text, component.hlgroup:embed(component.text))
      break
    end
  end
end

function M.Line:clickable()
  return format('%%%s@cokeline#handle_click@%s', self.buffer.number, self.text)
end

return M
