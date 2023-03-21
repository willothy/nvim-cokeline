-- local math_abs = math.abs
local floor = math.floor
local max = math.max

---@type table
-- local gl_mut_prev_state

-- local gl_scrolloff = 5

---@param available_space  number
---@param width_left_of_current  number
---@param width_right_of_current  number
---@return number, number
local center_current_buffer = function(
  available_space,
  width_left_of_current,
  width_right_of_current
)
  local available_space_left = floor(available_space / 2)
  local available_space_right = available_space_left + available_space % 2

  local unused_space_left =
    max(available_space_left - width_left_of_current, 0)
  local unused_space_right =
    max(available_space_right - width_right_of_current, 0)

  return available_space_left - unused_space_left + unused_space_right,
    available_space_right - unused_space_right + unused_space_left
end

---@param available_space  number
---@param width_left_of_current  number
---@param width_right_of_current  number
---@return number, number
-- local slide_if_needed =
--   function(available_space, width_left_of_current, width_right_of_current,
--             current_buffer_index, prev_state)

--   -- The first time the bufferline is rendered there is no previous state, so..
--   if not gl_mut_prev_state then
--     return 0, available_space
--   end

--   -- If the new current buffer was not fully in view in the previous state we..
--   if current_buffer_index < prev_state.fully_in_view[1].index then
--     local left =
--       gl_scrolloff < width_left_of_current
--       and gl_scrolloff
--        or width_left_of_current
--     local right = available_space - left
--     return left, right

--   elseif current_buffer_index >
--           prev_state.fully_in_view[#prev_state.fully_in_view].index then
--     local right =
--       gl_scrolloff < width_right_of_current
--       and gl_scrolloff
--        or width_right_of_current
--     local left = available_space - right
--     return left, right
--   end

--   local index_range = math_abs(current_buffer_index - prev_state.current_index)
--   local j = prev_state.current_index < current_buffer_index and 1 or -1

--   local left, right = prev_state.spaces.left, prev_state.spaces.right
--   for i=1,index_range do
--     left = left + j * prev_state.fully_in_view[i].width
--     right = right - j * prev_state.fully_in_view[i + 1].width
--   end

--   return left, right
-- end

return {
  center_current_buffer = center_current_buffer,
  -- slide_if_needed = slide_if_needed,
}
