local buffers = require("cokeline/buffers")

local cmd = vim.cmd
local filter = vim.tbl_filter
local keymap = vim.keymap
local set_keymap = vim.api.nvim_set_keymap
local fn = vim.fn

local is_picking = {
  focus = false,
  close = false,
}

---@param goal  '"switch"' | '"focus"'
---@param index  index
local by_index = function(goal, index)
  local target_buffer = filter(function(buffer)
    return buffer.index == index
  end, _G.cokeline.visible_buffers)[1]

  if not target_buffer then
    return
  end

  if goal == "switch" then
    local focused_buffer = filter(function(buffer)
      return buffer.is_focused
    end, _G.cokeline.valid_buffers)[1]

    if not focused_buffer then
      return
    end

    buffers.move_buffer(focused_buffer, target_buffer._valid_index)
  elseif goal == "focus" then
    cmd("b" .. target_buffer.number)
  end
end

---@param goal  '"switch"' | '"focus"'
---@param step  '-1' | '1'
local by_step = function(goal, step)
  local focused_buffer = filter(function(buffer)
    return buffer.is_focused
  end, _G.cokeline.valid_buffers)[1]

  if not focused_buffer then
    return
  end

  local target_index = focused_buffer._valid_index + step
  if target_index < 1 or target_index > #_G.cokeline.valid_buffers then
    if not _G.cokeline.config.mappings.cycle_prev_next then
      return
    end
    target_index = (target_index - 1) % #_G.cokeline.valid_buffers + 1
  end

  if goal == "switch" then
    buffers.move_buffer(focused_buffer, target_index)
  elseif goal == "focus" then
    cmd("b" .. _G.cokeline.valid_buffers[target_index].number)
  end
end

---@param goal  '"focus"' | '"close"'
local pick = function(goal)
  is_picking[goal] = true
  cmd("redrawtabline")
  is_picking[goal] = false

  local letter = fn.nr2char(fn.getchar())
  local target_buffer = filter(function(buffer)
    return buffer.pick_letter == letter
  end, _G.cokeline.visible_buffers)[1]

  if not target_buffer or (goal == "focus" and target_buffer.is_focused) then
    cmd("redrawtabline")
    return
  end

  if goal == "focus" then
    cmd("b" .. target_buffer.number)
  elseif goal == "close" then
    cmd(("bd%s | redrawtabline"):format(target_buffer.number))
  end
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

    keymap.set("n", "<Plug>(cokeline-pick-focus)", function()
      pick("close")
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
