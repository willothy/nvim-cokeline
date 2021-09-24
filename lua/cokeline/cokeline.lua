local utils = require('cokeline/utils')

local map = vim.tbl_map

local concat = table.concat
local insert = table.insert
local unpack = unpack or table.unpack

local M = {}

M.Cokeline = {
  main = '',
  width = 0,
  lines = {},
  before = '',
  after = '',
}

local conclines = function(lines)
  return concat(map(
      function(line) return line:text() end,
      lines
  ))
end

function M.Cokeline:new()
  local cokeline = {}
  setmetatable(cokeline, self)
  self.__index = self
  cokeline.main = ''
  cokeline.width = 0
  cokeline.lines = {}
  cokeline.before = ''
  cokeline.after = ''
  return cokeline
end

function M.Cokeline:add_line(line)
  self.width = self.width + line.width
  insert(self.lines, line)
end

function M.Cokeline:subline(args)
  local direction, lines

  if args.upto then
    direction = 'left'
    lines = utils.reverse({unpack(self.lines, 1, args.upto)})
  elseif args.startfrom then
    direction = 'right'
    lines = {unpack(self.lines, args.startfrom)}
  end

  local subline = M.Cokeline:new()

  for _, line in ipairs(lines) do
    if subline.width + line.width < args.available_space then
      subline:add_line(line)
    else
      line:cutoff({
        direction = direction,
        available_space = args.available_space - subline.width
      })
      subline:add_line(line)
      break
    end
  end

  if args.upto then
    subline.lines = utils.reverse(subline.lines)
  end

  return conclines(subline.lines)
end

function M.Cokeline:render(focused_line)
  local available_space_tot = vim.o.columns

  local available_space_minus_flwidth =
    available_space_tot - focused_line.width

  if available_space_minus_flwidth <= 0 then
    self.lines[focused_line.index]:cutoff({
      direction = 'right',
      available_space = available_space_tot,
    })
    self.main = self.lines[focused_line.index]:text()
    return
  end

  local available_space_left_right =
    math.floor((available_space_minus_flwidth)/2)

  local available_space = {
    left = available_space_left_right,
    right = available_space_left_right + available_space_minus_flwidth % 2,
  }

  local width_left_of_focused_line = focused_line.colstart - 1
  local width_right_of_focused_line = self.width - focused_line.colend

  local unused_space = {
    left = available_space.left - width_left_of_focused_line,
    right = available_space.right - width_right_of_focused_line,
  }

  local left, right

  if unused_space.left >= 0 then
    left = conclines({unpack(self.lines, 1, focused_line.index - 1)})
  else
    left = self:subline({
      upto = focused_line.index - 1,
      available_space = available_space.left + math.max(unused_space.right, 0),
    })
  end

  if unused_space.right >= 0 then
    right = conclines({unpack(self.lines, focused_line.index + 1)})
  else
    right = self:subline({
      startfrom = focused_line.index + 1,
      available_space = available_space.right + math.max(unused_space.left, 0),
    })
  end

  self.main = left .. self.lines[focused_line.index]:text() .. right
end

return M
