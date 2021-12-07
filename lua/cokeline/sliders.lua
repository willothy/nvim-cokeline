local math_floor = math.floor
local math_max = math.max

local gl_scrolloff = 5

---@param available_space  number
---@param width_left_of_current  number
---@param width_right_of_current  number
---@return number, number
local center_current_buffer =
  function(available_space, width_left_of_current, width_right_of_current)

  local available_space_left = math_floor(available_space / 2)
  local available_space_right = available_space_left + available_space % 2

  local unused_space_left =
    math_max(available_space_left - width_left_of_current, 0)
  local unused_space_right =
    math_max(available_space_right - width_right_of_current, 0)

  return
    available_space_left - unused_space_left + unused_space_right,
    available_space_right - unused_space_right + unused_space_left
end

---@param available_space  number
---@param width_left_of_current  number
---@param width_right_of_current  number
---@return number, number
local slide_if_needed =
  function(available_space, width_left_of_current, width_right_of_current)

  return gl_scrolloff, gl_scrolloff
end

return {
  center_current_buffer = center_current_buffer,
  slide_if_needed = slide_if_needed,
}
