local cmd = vim.cmd
local filter = vim.tbl_filter
local fn = vim.fn
local opt = vim.opt

local toggle = function()
  local listed_buffers = fn.getbufinfo({ buflisted = 1 })
  opt.showtabline = #listed_buffers > 0 and 2 or 0
end

local bufnr_to_close

local close_bufnr = function()
  if bufnr_to_close then
    cmd("b" .. bufnr_to_close)
    bufnr_to_close = nil
  end
end

---@param bufnr  number
local remember_bufnr = function(bufnr)
  if #_G.cokeline.valid_buffers == 1 then
    return
  end

  local deleted_buffer = filter(function(buffer)
    return buffer.number == bufnr
  end, _G.cokeline.valid_buffers)[1]

  -- Neogit buffers do some weird stuff like closing themselves on buffer
  -- change and seem to cause problems. We just ignore them.
  -- See https://github.com/noib3/nvim-cokeline/issues/43
  if
    not deleted_buffer or deleted_buffer.filename:find("Neogit", nil, true)
  then
    return
  end

  local target_index

  if _G.cokeline.config.buffers.focus_on_delete == "prev" then
    target_index = deleted_buffer._valid_index ~= 1
        and deleted_buffer._valid_index - 1
      or 2
  elseif _G.cokeline.config.buffers.focus_on_delete == "next" then
    target_index = deleted_buffer._valid_index ~= #_G.cokeline.valid_buffers
        and deleted_buffer._valid_index + 1
      or #_G.cokeline.valid_buffers - 1
  end

  bufnr_to_close = _G.cokeline.valid_buffers[target_index].number
end

local setup = function()
  cmd([[
  augroup cokeline_toggle
    autocmd VimEnter,BufAdd * lua require('cokeline/augroups').toggle()
  augroup END
  ]])

  if _G.cokeline.config.buffers.focus_on_delete then
    -- We use two different events here: on `BufUnload` we check if the buffer
    -- closed was a valid one, and if it was we save its number in
    -- `bufnr_to_close`. Then, on `BufDelete` we check if `bufnr_to_close` has
    -- a value. If it does we focus the buffer with that number, and set its
    -- value back to `nil`.
    --
    -- Focusing buffers directly on `BufUnload` seems to cause all kind of
    -- weird behaviour like #44, while only using `BufDelete` causes the
    -- focused buffer to change everytime a `vim-floaterm` is closed (and
    -- probably other issues too, that's the only one I've personally
    -- experienced).
    cmd([[
    augroup cokeline_focus
      autocmd BufUnload *
        \ exe printf(
        \   'lua require("cokeline/augroups").remember_bufnr(%s)',
        \   expand('<abuf>')
        \ )
      autocmd BufDelete * lua require("cokeline/augroups").close_bufnr()
    augroup END
    ]])
  end
end

return {
  close_bufnr = close_bufnr,
  remember_bufnr = remember_bufnr,
  setup = setup,
  toggle = toggle,
}
