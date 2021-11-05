local reverse = require('cokeline/utils').reverse

local concat = table.concat
local insert = table.insert

local map = vim.tbl_map
local fn = vim.fn

local M = {}

local render_lines = function(args)
  if not next(args.lines) then
    return ''
  end

  if args.direction == 'left' then
    args.lines = reverse(args.lines)
  end

  local lines = {}
  local remaining_space = args.available_space
  local cutoff_string_width = fn.strwidth(
    args.lines[1].components[1].cutoff_fmt[args.direction]:format(''))

  for i, line in ipairs(args.lines) do
    if (remaining_space > line.width)
        or (remaining_space == line.width and i == #args.lines) then
      insert(lines, line)
      remaining_space = remaining_space - line.width
    else
      -- If the remaining space is less than the width of the empty cutoff
      -- string we cutoff the previous line.
      if remaining_space < cutoff_string_width then
        lines[i - 1] = lines[i - 1]:cutoff({
          direction = args.direction,
          available_space = lines[i - 1].width + remaining_space,
        })
        break
      end
      line = line:cutoff({
        direction = args.direction,
        available_space = remaining_space,
      })
      insert(lines, line)
      break
    end
  end

  if args.direction == 'left' then
    lines = reverse(lines)
  end

  return concat(map(function(line) return line:render() end, lines))
end

M.default = function(lines, available_space_tot)
  local available_space_sides = available_space_tot - lines.center.width

  if available_space_sides <= 0 then
    return lines.center:truncate({
      available_space = available_space_tot,
    }):render()
  end

  local available_space = {
    left = math.floor(available_space_sides/2),
    right = math.floor(available_space_sides/2) + available_space_sides % 2,
  }

  local unused_space = {
    left = math.max(available_space.left - lines.width.left, 0),
    right = math.max(available_space.right - lines.width.right, 0),
  }

  local left = render_lines({
    lines = lines.left,
    available_space = available_space.left + unused_space.right,
    direction = 'left',
  })

  local right = render_lines({
    lines = lines.right,
    available_space = available_space.right + unused_space.left,
    direction = 'right',
  })

  return left .. lines.center:render() .. right
end

return M
