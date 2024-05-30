local lazy = require("cokeline.lazy")
local state = lazy("cokeline.state")
local buffers = lazy("cokeline.buffers")

local cmd = vim.cmd
local filter = vim.tbl_filter
local keymap = vim.keymap
local set_keymap = vim.api.nvim_set_keymap
local fn = vim.fn

local is_picking = {
  focus = false,
  close = false,
}

---@param goal  '"switch"' | '"focus"' | '"close"' | fun(buf: Buffer)
---@param index  index
local by_index = function(goal, index)
  local target_buffer = filter(function(buffer)
    return buffer.index == index
  end, state.visible_buffers)[1]

  if not target_buffer then
    return
  end

  if goal == "switch" then
    local focused_buffer = filter(function(buffer)
      return buffer.is_focused
    end, state.valid_buffers)[1]

    if not focused_buffer then
      return
    end

    buffers.move_buffer(focused_buffer, target_buffer._valid_index)
  elseif goal == "focus" then
    target_buffer:focus()
  elseif goal == "close" then
    target_buffer:delete()
  elseif type(goal) == "function" then
    goal(target_buffer)
  end
end

---@param goal  '"switch"' | '"focus"' |'"close"' | fun(buf: Buffer, did_fallback: boolean)
---@param step  -1 | 1
local by_step = function(goal, step)
  local config = lazy("cokeline.config")
  local focused_buffer = filter(function(buffer)
    return buffer.is_focused
  end, state.valid_buffers)[1]

  local target_buf
  local target_idx
  local did_fallback = false
  if focused_buffer then
    target_idx = focused_buffer._valid_index + step
    if target_idx < 1 or target_idx > #state.valid_buffers then
      if not config.mappings.cycle_prev_next then
        return
      end
      target_idx = (target_idx - 1) % #state.valid_buffers + 1
    end
    target_buf = state.valid_buffers[target_idx]
  elseif goal == "focus" and config.history.enabled then
    did_fallback = true
    target_buf = require("cokeline.history"):last()
    if step < -1 then
      -- The result of history:last() is the index -1,
      -- so we need to step back one more.
      step = step + 1
    end
    if target_buf and step ~= 0 then
      local step_buf = state.valid_buffers[target_buf._valid_index + step]
      if step_buf then
        target_buf = step_buf
      end
    end
  else
    return
  end

  if target_buf then
    if goal == "switch" then
      buffers.move_buffer(focused_buffer, target_idx)
    elseif goal == "focus" then
      target_buf:focus()
    elseif goal == "close" and not did_fallback then
      target_buf:delete()
    elseif type(goal) == "function" then
      goal(target_buf, did_fallback)
    end
  end
end

---@param goal  '"focus"' | '"close"' | '"close-multiple"' | fun(buf: Buffer)
local pick = function(goal)
  local close_multiple = false
  if goal == "close-multiple" then
    goal = "close"
    close_multiple = true
  end

  is_picking[goal] = true
  cmd("redrawtabline")

  repeat
    local valid_char, char = pcall(fn.getchar)
    if not close_multiple then
      is_picking[goal] = false
    end

    -- bail out on keyboard interrupt
    if not valid_char then
      char = 0
    end

    local letter = fn.nr2char(char)
    local target_buffer = filter(function(buffer)
      return buffer.pick_letter == letter
    end, state.visible_buffers)[1]

    if not target_buffer or (goal == "focus" and target_buffer.is_focused) then
      is_picking[goal] = false
      cmd("redrawtabline")
      return
    end

    if goal == "focus" then
      target_buffer:focus()
    elseif goal == "close" then
      target_buffer:delete()
    elseif type(goal) == "function" then
      goal(target_buffer)
    end
  until not is_picking[goal]
end

local setup = function()
  if keymap then
    keymap.set("n", "<Plug>(cokeline-switch-prev)", function()
      by_step("switch", -1)
    end)

    keymap.set("n", "<Plug>(cokeline-switch-next)", function()
      by_step("switch", 1)
    end)

    keymap.set("n", "<Plug>(cokeline-focus-prev)", function()
      by_step("focus", -1)
    end)

    keymap.set("n", "<Plug>(cokeline-focus-next)", function()
      by_step("focus", 1)
    end)

    keymap.set("n", "<Plug>(cokeline-pick-focus)", function()
      pick("focus")
    end)

    keymap.set("n", "<Plug>(cokeline-pick-close)", function()
      pick("close")
    end)

    keymap.set("n", "<Plug>(cokeline-pick-close-multiple)", function()
      pick("close-multiple")
    end)

    for i = 1, 20 do
      keymap.set("n", ("<Plug>(cokeline-switch-%s)"):format(i), function()
        by_index("switch", i)
      end, {})

      keymap.set("n", ("<Plug>(cokeline-focus-%s)"):format(i), function()
        by_index("focus", i)
      end, {})
    end
  else
    set_keymap(
      "n",
      "<Plug>(cokeline-switch-prev)",
      '<Cmd>lua require"cokeline/mappings".by_step("switch", -1)<CR>',
      {}
    )
    set_keymap(
      "n",
      "<Plug>(cokeline-switch-next)",
      '<Cmd>lua require"cokeline/mappings".by_step("switch", 1)<CR>',
      {}
    )
    set_keymap(
      "n",
      "<Plug>(cokeline-focus-prev)",
      '<Cmd>lua require"cokeline/mappings".by_step("focus", -1)<CR>',
      {}
    )
    set_keymap(
      "n",
      "<Plug>(cokeline-focus-next)",
      '<Cmd>lua require"cokeline/mappings".by_step("focus", 1)<CR>',
      {}
    )
    set_keymap(
      "n",
      "<Plug>(cokeline-pick-focus)",
      '<Cmd>lua require"cokeline/mappings".pick("focus")<CR>',
      {}
    )
    set_keymap(
      "n",
      "<Plug>(cokeline-pick-close)",
      '<Cmd>lua require"cokeline/mappings".pick("close")<CR>',
      {}
    )
    set_keymap(
      "n",
      "<Plug>(cokeline-pick-close-multiple)",
      '<Cmd>lua require"cokeline/mappings".pick("close-multiple")<CR>',
      {}
    )
    for i = 1, 20 do
      set_keymap(
        "n",
        ("<Plug>(cokeline-switch-%s)"):format(i),
        ('<Cmd>lua require"cokeline/mappings".by_index("switch", %s)<CR>'):format(
          i
        ),
        {}
      )

      set_keymap(
        "n",
        ("<Plug>(cokeline-focus-%s)"):format(i),
        ('<Cmd>lua require"cokeline/mappings".by_index("focus", %s)<CR>'):format(
          i
        ),
        {}
      )
    end
  end
end

return {
  by_index = by_index,
  by_step = by_step,
  is_picking_focus = function()
    return is_picking.focus
  end,
  is_picking_close = function()
    return is_picking.close
  end,
  pick = pick,
  setup = setup,
}
