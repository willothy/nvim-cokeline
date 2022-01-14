local vim_cmd = vim.cmd
local vim_fn = vim.fn
local vim_keymap = vim.api.nvim_set_keymap
local vim_opt = vim.opt

local gl_settings

---@type Buffer[]
local gl_mut_valid_buffers

---@type Buffer[]
local gl_mut_visible_buffers

local gl_mut_is_picking = {
  focus = false,
  close = false,
}

---@param buffers  Buffer[]
local set_valid_buffers = function(buffers)
  gl_mut_valid_buffers = buffers
end

---@param buffers  Buffer[]
local set_visible_buffers = function(buffers)
  gl_mut_visible_buffers = buffers
end

---@param buffers  Buffer[]
---@param current  vidx
---@param step  '-1' | '1'
---@param cycle_prev_next  boolean
---@return vidx | nil
local get_vidx_from_step = function(buffers, current, step, cycle_prev_next)
  local target = current + step
  return
    (buffers[target] and target)
    or (cycle_prev_next and (target - 1) % #buffers + 1)
    or nil
end

---@param buffers  Buffer[]
---@param condition  function(buffer: Buffer): boolean
---@return vidx | nil
local get_vidx_from_condition = function(buffers, condition)
  for _, buffer in pairs(buffers) do
    if condition(buffer) then return buffer._vidx end
  end
end

---@param goal  '"switch"' | '"focus"'
---@param index  index
local by_index = function(goal, index)
  local target = get_vidx_from_condition(
    gl_mut_visible_buffers, function(buffer) return buffer.index == index end)
  if not target then return end

  if goal == 'switch' then
    local current = get_vidx_from_condition(
      gl_mut_valid_buffers, function(buffer) return buffer.is_focused end)
    if not current then return end

    require('cokeline/buffers').switch_bufnrs_order(current, target)
  elseif goal == 'focus' then
    vim_cmd('buffer ' .. gl_mut_valid_buffers[target].number)
  end
end

---@param goal  '"switch"' | '"focus"'
---@param step  '-1' | '1'
local by_step = function(goal, step)
  if vim_opt.showtabline._value == 0 then
    gl_mut_valid_buffers = require('cokeline/buffers').get_valid_buffers()
  end

  local current = get_vidx_from_condition(
    gl_mut_valid_buffers, function(buffer) return buffer.is_focused end)
  if not current then return end

  local target = get_vidx_from_step(
    gl_mut_valid_buffers, current, step, gl_settings.cycle_prev_next)
  if not target then return end

  if goal == 'switch' then
    require('cokeline/buffers').switch_bufnrs_order(current, target)
  elseif goal == 'focus' then
    vim_cmd('buffer ' .. gl_mut_valid_buffers[target].number)
  end
end

---@param goal  '"focus"' | '"close"'
local pick = function(goal)
  gl_mut_is_picking[goal] = true
  vim_cmd('redrawtabline')
  gl_mut_is_picking[goal] = false

  local letter = vim_fn.nr2char(vim_fn.getchar())
  local target = get_vidx_from_condition(
    gl_mut_visible_buffers,
    function(buffer) return buffer.pick_letter == letter end
  )

  if not target
      or (goal == 'focus' and gl_mut_valid_buffers[target].is_focused) then
    vim_cmd('redrawtabline')
    return
  end

  local bufnr = gl_mut_valid_buffers[target].number
  if goal == 'focus' then
    vim_cmd('buffer ' .. bufnr)
  elseif goal == 'close' then
    vim_cmd(('bd %s | redrawtabline'):format(bufnr))
  end
end

---@param settings  table
local setup = function(settings)
  gl_settings = settings

  ---@param lhs  string
  ---@param rhs  string
  local plugmap = function(lhs, rhs)
    vim_keymap('n', lhs, rhs, {noremap = true, silent = true})
  end

  for i=1,20 do
    plugmap(
      ('<Plug>(cokeline-switch-%s)'):format(i),
      ('<Cmd>lua require"cokeline/mappings".by_index("switch", %s)<CR>'):format(i)
    )
    plugmap(
      ('<Plug>(cokeline-focus-%s)'):format(i),
      ('<Cmd>lua require"cokeline/mappings".by_index("focus", %s)<CR>'):format(i)
    )
  end

  plugmap(
    '<Plug>(cokeline-switch-prev)',
    '<Cmd>lua require"cokeline/mappings".by_step("switch", -1)<CR>'
  )
  plugmap(
    '<Plug>(cokeline-switch-next)',
    '<Cmd>lua require"cokeline/mappings".by_step("switch", 1)<CR>'
  )
  plugmap(
    '<Plug>(cokeline-focus-prev)',
    '<Cmd>lua require"cokeline/mappings".by_step("focus", -1)<CR>'
  )
  plugmap(
    '<Plug>(cokeline-focus-next)',
    '<Cmd>lua require"cokeline/mappings".by_step("focus", 1)<CR>'
  )

  plugmap(
    '<Plug>(cokeline-pick-focus)',
    '<Cmd>lua require"cokeline/mappings".pick("focus")<CR>'
  )
  plugmap(
    '<Plug>(cokeline-pick-close)',
    '<Cmd>lua require"cokeline/mappings".pick("close")<CR>'
  )
end

return {
  set_valid_buffers = set_valid_buffers,
  set_visible_buffers = set_visible_buffers,
  by_index = by_index,
  by_step = by_step,
  is_picking_focus = function() return gl_mut_is_picking.focus end,
  is_picking_close = function() return gl_mut_is_picking.close end,
  pick = pick,
  setup = setup,
}
