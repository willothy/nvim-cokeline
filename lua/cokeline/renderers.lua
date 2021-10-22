local M = {}

M.default = function(cokeline, focused_line)
  local fl = cokeline.lines[focused_line.index]

  local available_space_tot = vim.o.columns

  local available_space_minus_flwidth =
    available_space_tot - focused_line.width

  if available_space_minus_flwidth <= 0 then
    fl:cutoff({
      direction = 'right',
      available_space = available_space_tot,
    })
    cokeline.main = fl:text()
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
    left = math.max(available_space.left - width_left_of_focused_line, 0),
    right = math.max(available_space.right - width_right_of_focused_line, 0),
  }

  local left = cokeline:subline({
    upto = focused_line.index - 1,
    available_space = available_space.left + unused_space.right,
  })

  local right = cokeline:subline({
    startfrom = focused_line.index + 1,
    available_space = available_space.right + unused_space.left,
  })

  cokeline.main = left .. fl:text() .. right
end

return M
