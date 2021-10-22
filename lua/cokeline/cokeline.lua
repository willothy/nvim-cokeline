local renderers = require('cokeline/renderers')
local reverse = require('cokeline/utils').reverse

local unpack = unpack or table.unpack
local concat = table.concat
local insert = table.insert

local map = vim.tbl_map
local fn = vim.fn

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

  local remaining_space = args.available_space
  local sublines = {}

  for i, line in ipairs(lines) do
    if (remaining_space > line.width)
        or (remaining_space == line.width and i == #lines) then
      insert(sublines, line)
      remaining_space = remaining_space - line.width
    else
      -- If the remaining space is less than the width of the cutoff format we
      -- cutoff the previous line.
      if remaining_space <
          fn.strwidth(line.components[1].cutoff_fmt[direction]:format('')) then
        sublines[i - 1]:cutoff({
          direction = direction,
          available_space = sublines[i - 1].width + remaining_space,
        })
        break
      end
      line:cutoff({
        direction = direction,
        available_space = remaining_space,
      })
      insert(sublines, line)
      break
    end
  end

  if direction == 'left' then
    sublines = reverse(sublines)
  end

  return concat(map(function(line)
    return line:text()
  end, sublines))
end

function M.Cokeline:render(settings)
  if settings.default.enable then
    renderers.default(self, focused_line)
  end
end

return M
