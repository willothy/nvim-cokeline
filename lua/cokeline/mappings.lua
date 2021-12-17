local vim_cmd = vim.cmd
local vim_fn = vim.fn
local vim_keymap = vim.api.nvim_set_keymap
local vim_opt = vim.opt

local gl_settings

---@type Buffer[]
local gl_mut_valid_buffers

---@type Buffer[]
local gl_mut_visible_buffers

local gl_mut_is_picking_focus = false

local gl_mut_is_picking_close = false

---@param buffers  Buffer[]
local set_valid_buffers = function(buffers)
  gl_mut_valid_buffers = buffers
end

---@param buffers  Buffer[]
local set_visible_buffers = function(buffers)
  gl_mut_visible_buffers = buffers
end

---@return vidx | nil
local get_current_vidx = function()
  for _, buffer in pairs(gl_mut_valid_buffers) do
    if buffer.is_focused then return buffer._vidx end
  end
end

---@param current  vidx
---@param step  '-1' | '1'
---@return vidx | nil
local get_vidx_from_step = function(current, step)
  local target = current + step
  if target < 1 or target > #gl_mut_valid_buffers then
    if not gl_settings.cycle_prev_next then return end
    return (target - 1) % #gl_mut_valid_buffers + 1
  end
  return target
end

---@param index  index
---@return vidx | nil
local get_vidx_from_index = function(index)
  for _, buffer in pairs(gl_mut_visible_buffers) do
    if buffer.index == index then return buffer._vidx end
  end
end

---@param letter  string
---@return vidx | nil
local get_vidx_from_letter = function(letter)
  for _, buffer in pairs(gl_mut_visible_buffers) do
    if buffer.pick_letter == letter then return buffer._vidx end
  end
end

---@param vidx1  vidx
---@param vidx2  vidx
local switch_buffer_order = function(vidx1, vidx2)
  local rq_buffers = require('cokeline/buffers')
  rq_buffers.switch_bufnrs_order(vidx1, vidx2)
  vim_cmd('redrawtabline')
end

---@param index  index
local switch_by_index = function(index)
  local current = get_current_vidx()
  if not current then return end
  local target = get_vidx_from_index(index)
  if not target then return end
  switch_buffer_order(current, target)
end

---@param step  '-1' | '1'
local switch_by_step = function(step)
  if vim_opt.showtabline._value == 0 then
    local rq_buffers = require('cokeline/buffers')
    gl_mut_valid_buffers = rq_buffers.get_valid_buffers()
  end
  local current = get_current_vidx()
  if not current then return end
  local target = get_vidx_from_step(current, step)
  if not target then return end
  switch_buffer_order(current, target)
end

---@param index  index
local focus_by_index = function(index)
  local target = get_vidx_from_index(index)
  if not target then return end
  vim_cmd('buffer ' .. gl_mut_valid_buffers[target].number)
end

---@param step  '-1' | '1'
local focus_by_step = function(step)
  if vim_opt.showtabline._value == 0 then
    local rq_buffers = require('cokeline/buffers')
    gl_mut_valid_buffers = rq_buffers.get_valid_buffers()
  end
  local current = get_current_vidx()
  if not current then return end
  local target = get_vidx_from_step(current, step)
  if not target then return end
  vim_cmd('buffer ' .. gl_mut_valid_buffers[target].number)
end

local pick_to_focus = function()
  gl_mut_is_picking_focus = true
  vim_cmd('redrawtabline')
  gl_mut_is_picking_focus = false
  local letter = vim_fn.nr2char(vim_fn.getchar())
  local target = get_vidx_from_letter(letter)
  if not target or gl_mut_valid_buffers[target].is_focused then
    vim_cmd('redrawtabline')
    return
  end
  vim_cmd('buffer ' .. gl_mut_valid_buffers[target].number)
end

local pick_to_close = function()
  gl_mut_is_picking_close = true
  vim_cmd('redrawtabline')
  gl_mut_is_picking_close = false
  local letter = vim_fn.nr2char(vim_fn.getchar())
  local target = get_vidx_from_letter(letter)
  if not target then
    vim_cmd('redrawtabline')
    return
  end
  vim_cmd('bdelete ' .. gl_mut_valid_buffers[target].number)
  vim_cmd('redrawtabline')
end

---@param lhs  string
---@param rhs  string
local plugmap = function(lhs, rhs)
  vim_keymap('n', lhs, rhs, {noremap = true, silent = true})
end

---@param settings  table
local setup = function(settings)
  gl_settings = settings

  for i=1,20 do
    plugmap(
      ('<Plug>(cokeline-switch-%s)'):format(i),
      ('<Cmd>lua require"cokeline/mappings".switch_by_index(%s)<CR>'):format(i)
    )
    plugmap(
      ('<Plug>(cokeline-focus-%s)'):format(i),
      ('<Cmd>lua require"cokeline/mappings".focus_by_index(%s)<CR>'):format(i)
    )
  end

  plugmap(
    '<Plug>(cokeline-switch-prev)',
    '<Cmd>lua require"cokeline/mappings".switch_by_step(-1)<CR>'
  )
  plugmap(
    '<Plug>(cokeline-switch-next)',
    '<Cmd>lua require"cokeline/mappings".switch_by_step(1)<CR>'
  )
  plugmap(
    '<Plug>(cokeline-focus-prev)',
    '<Cmd>lua require"cokeline/mappings".focus_by_step(-1)<CR>'
  )
  plugmap(
    '<Plug>(cokeline-focus-next)',
    '<Cmd>lua require"cokeline/mappings".focus_by_step(1)<CR>'
  )

  plugmap(
    '<Plug>(cokeline-pick-focus)',
    '<Cmd>lua require"cokeline/mappings".pick_to_focus()<CR>'
  )
  plugmap(
    '<Plug>(cokeline-pick-close)',
    '<Cmd>lua require"cokeline/mappings".pick_to_close()<CR>'
  )
end

return {
  set_valid_buffers = set_valid_buffers,
  set_visible_buffers = set_visible_buffers,
  switch_by_index = switch_by_index,
  switch_by_step = switch_by_step,
  focus_by_index = focus_by_index,
  focus_by_step = focus_by_step,
  is_picking_focus = function() return gl_mut_is_picking_focus end,
  is_picking_close = function() return gl_mut_is_picking_close end,
  pick_to_focus = pick_to_focus,
  pick_to_close = pick_to_close,
  setup = setup,
}
