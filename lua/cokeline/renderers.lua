local concat = table.concat
local map = vim.tbl_map

local M = {}

local conclines = function(lines)
  return concat(map(function(line)
    return line:text()
  end, lines))
end

M.default = function(cokeline, focused_line)
  local available_space_tot = vim.o.columns

  local available_space_minus_flwidth =
    available_space_tot - focused_line.width

  if available_space_minus_flwidth <= 0 then
    cokeline.lines[focused_line.index]:cutoff({
      direction = 'right',
      available_space = available_space_tot,
    })
    cokeline.main = cokeline.lines[focused_line.index]:text()
    return
  end

  local available_space_left_right =
    math.floor((available_space_minus_flwidth)/2)

  local available_space = {
    left = available_space_left_right,
    right = available_space_left_right + available_space_minus_flwidth % 2,
  }

  local width_left_of_focused_line = focused_line.colstart - 1
  local width_right_of_focused_line = cokeline.width - focused_line.colend

  local unused_space = {
    left = available_space.left - width_left_of_focused_line,
    right = available_space.right - width_right_of_focused_line,
  }

  local left, right

  if unused_space.left >= 0 then
    left = conclines({unpack(cokeline.lines, 1, focused_line.index - 1)})
  else
    local left_lines = cokeline:subline({
      upto = focused_line.index - 1,
      available_space = available_space.left + math.max(unused_space.right, 0),
    })
    left = conclines(left_lines)
  end

  if unused_space.right >= 0 then
    right = conclines({unpack(cokeline.lines, focused_line.index + 1)})
  else
    local right_lines = cokeline:subline({
      startfrom = focused_line.index + 1,
      available_space = available_space.right + math.max(unused_space.left, 0),
    })
    right = conclines(right_lines)
  end

  cokeline.main = left .. cokeline.lines[focused_line.index]:text() .. right
end

return M
