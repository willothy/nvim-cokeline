local buffers = require("cokeline/buffers")

local vim_cmd = vim.cmd
local vim_filter = vim.tbl_filter
local vim_fn = vim.fn
local vim_keymap = vim.api.nvim_set_keymap

local gl_settings

local gl_mut_is_picking = {
  focus = false,
  close = false,
}

---@param goal  '"switch"' | '"focus"'
---@param index  index
local by_index = function(goal, index)
  local target_buffer = vim_filter(function(buffer)
    return buffer.index == index
  end, _G.cokeline.visible_buffers)[1]
  if not target_buffer then
    return
  end

  if goal == "switch" then
    local current_buffer = vim_filter(function(buffer)
      return buffer.is_focused
    end, _G.cokeline.valid_buffers)[1]
    if not current_buffer then
      return
    end
    buffers.move_buffer(current_buffer, target_buffer._valid_index)
  elseif goal == "focus" then
    vim_cmd("b" .. target_buffer.number)
  end
end

---@param cmd  '"switch"' | '"focus"'
---@param step  '-1' | '1'
local by_step = function(cmd, step)
  local current_buffer = vim_filter(function(buffer)
    return buffer.is_focused
  end, _G.cokeline.valid_buffers)[1]
  if not current_buffer then
    return
  end

  local target_valid_index = current_buffer._valid_index + step
  local target_buffer = _G.cokeline.valid_buffers[target_valid_index]
    or (gl_settings.cycle_prev_next and _G.cokeline.valid_buffers[(target_valid_index - 1) % #_G.cokeline.valid_buffers + 1])
    or nil
  if not target_buffer then
    return
  end

  local _ = (
      cmd == "switch"
      and buffers.move_buffer(current_buffer, target_buffer._valid_index)
    ) or (cmd == "focus" and vim_cmd("b" .. target_buffer.number))
end

---@param cmd  '"focus"' | '"close"'
local pick = function(cmd)
  gl_mut_is_picking[cmd] = true
  vim_cmd("redrawtabline")
  gl_mut_is_picking[cmd] = false

  local letter = vim_fn.nr2char(vim_fn.getchar())
  local target_buffer = vim_filter(function(buffer)
    return buffer.pick_letter == letter
  end, _G.cokeline.visible_buffers)[1]

  if not target_buffer or (cmd == "focus" and target_buffer.is_focused) then
    vim_cmd("redrawtabline")
    return
  end

  local _ = (cmd == "focus" and vim_cmd("b" .. target_buffer.number))
    or (
      cmd == "close"
      and vim_cmd(("bd%s | redrawtabline"):format(target_buffer.number))
    )
end

---@param settings  table
local setup = function(settings)
  gl_settings = settings

  ---@param lhs  string
  ---@param rhs  string
  local plugmap = function(lhs, rhs)
    vim_keymap("n", lhs, rhs, { noremap = true, silent = true })
  end

  for i = 1, 20 do
    plugmap(
      ("<Plug>(cokeline-switch-%s)"):format(i),
      ('<Cmd>lua require"cokeline/mappings".by_index("switch", %s)<CR>'):format(
        i
      )
    )
    plugmap(
      ("<Plug>(cokeline-focus-%s)"):format(i),
      ('<Cmd>lua require"cokeline/mappings".by_index("focus", %s)<CR>'):format(
        i
      )
    )
  end

  plugmap(
    "<Plug>(cokeline-switch-prev)",
    '<Cmd>lua require"cokeline/mappings".by_step("switch", -1)<CR>'
  )
  plugmap(
    "<Plug>(cokeline-switch-next)",
    '<Cmd>lua require"cokeline/mappings".by_step("switch", 1)<CR>'
  )
  plugmap(
    "<Plug>(cokeline-focus-prev)",
    '<Cmd>lua require"cokeline/mappings".by_step("focus", -1)<CR>'
  )
  plugmap(
    "<Plug>(cokeline-focus-next)",
    '<Cmd>lua require"cokeline/mappings".by_step("focus", 1)<CR>'
  )

  plugmap(
    "<Plug>(cokeline-pick-focus)",
    '<Cmd>lua require"cokeline/mappings".pick("focus")<CR>'
  )
  plugmap(
    "<Plug>(cokeline-pick-close)",
    '<Cmd>lua require"cokeline/mappings".pick("close")<CR>'
  )
end

return {
  by_index = by_index,
  by_step = by_step,
  is_picking_focus = function()
    return gl_mut_is_picking.focus
  end,
  is_picking_close = function()
    return gl_mut_is_picking.close
  end,
  pick = pick,
  setup = setup,
}
