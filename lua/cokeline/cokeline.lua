local renderers = require('cokeline/renderers')
local reverse = require('cokeline/utils').reverse

local unpack = unpack or table.unpack
local insert = table.insert

local M = {}

local focused_line = {}

M.Cokeline = {
  before = '',
  main = '',
  after = '',
  width = 0,
  lines = {},
}

function M.Cokeline:new()
  local cokeline = {}
  setmetatable(cokeline, self)
  self.__index = self
  cokeline.before = ''
  cokeline.main = ''
  cokeline.after = ''
  cokeline.width = 0
  cokeline.lines = {}
  return cokeline
end

function M.Cokeline:add_line(line)
  if line.buffer.is_focused then
    focused_line = {
      width = line.width,
      index = line.buffer.index,
      colstart = self.width + 1,
      colend = self.width + line.width,
    }
  end

  self.width = self.width + line.width
  insert(self.lines, line)
end

function M.Cokeline:subline(args)
  local direction, lines

  if args.upto then
    direction = 'left'
    lines = reverse({unpack(self.lines, 1, args.upto)})
  elseif args.startfrom then
    direction = 'right'
    lines = {unpack(self.lines, args.startfrom)}
  end

  local subline = M.Cokeline:new()

  local remaining_space = args.available_space

  for _, line in ipairs(lines) do
    if line.width < remaining_space then
      subline:add_line(line)
      remaining_space = remaining_space - line.width
    else
      line:cutoff({
        direction = direction,
        available_space = remaining_space,
      })
      subline:add_line(line)
      break
    end
  end

  if args.upto then
    subline.lines = reverse(subline.lines)
  end

  return subline.lines
end

function M.Cokeline:render(settings)
  if settings.default.enable then
    renderers.default(self, focused_line)
  end
end

return M
