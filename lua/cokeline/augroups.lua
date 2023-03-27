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
end

return {
  close_bufnr = close_bufnr,
  remember_bufnr = remember_bufnr,
  setup = setup,
  toggle = toggle,
}
