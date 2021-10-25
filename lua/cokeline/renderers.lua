local M = {}

M.default = function(cokeline, centered_l)
  -- 3 buffers, first 2 are visible, last one isn't. We focus the last buffer,
  -- then the 2nd, then close the 2nd. Without this check centered_index would
  -- still be 2, which would cause centered_line to be nil.
  local centered_index = centered_l.index
  while true do
    if cokeline.lines[centered_index] then
      break
    end
    centered_index = centered_index - 1
  end

  local centered_line = cokeline.lines[centered_index]

  local available_space_tot = vim.o.columns

  local available_space_sides = available_space_tot - centered_line.width

  if available_space_sides <= 0 then
    centered_line:cutoff({
      direction = 'right',
      available_space = available_space_tot,
    })
    cokeline.main = centered_line:text()
    return
  end

  local available_space = {
    left = math.floor(available_space_sides/2),
    right = math.floor(available_space_sides/2) + available_space_sides % 2,
  }

  local sides_width = {
    left = centered_l.colprv,
    right = cokeline.width - centered_l.colend,
  }

  local unused_space = {
    left = math.max(available_space.left - sides_width.left, 0),
    right = math.max(available_space.right - sides_width.right, 0),
  }

  local left = cokeline:subline({
    upto = centered_index - 1,
    available_space = available_space.left + unused_space.right,
  })

  local right = cokeline:subline({
    startfrom = centered_index + 1,
    available_space = available_space.right + unused_space.left,
  })

  cokeline.main = left .. centered_line:text() .. right
end

return M
