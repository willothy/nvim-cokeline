local vim_filter = vim.tbl_filter
local vim_fn = vim.fn
local vim_opt = vim.opt

local gl_settings

local toggle = function()
  local listed_buffers = vim_fn.getbufinfo({ buflisted = 1 })
  vim_opt.showtabline = #listed_buffers > 0 and 2 or 0
end

---@param bufnr  number
local focus_on_delete = function(bufnr)
  if #_G.cokeline.valid_buffers == 1 then
    return
  end

  local deleted_buffer = vim_filter(function(buffer)
    return buffer.number == bufnr
  end, _G.cokeline.valid_buffers)[1]

  -- Neogit buffers do some weird stuff like closing themselves when on buffer
  -- change, etc, and they cause problems.
  -- See https://github.com/noib3/nvim-cokeline/issues/43
  if
    not deleted_buffer or deleted_buffer.filename:find("Neogit", nil, true)
  then
    return
  end

  local prev_buffer =
    _G.cokeline.valid_buffers[deleted_buffer._valid_index ~= 1 and deleted_buffer._valid_index - 1 or 2]

  local next_buffer =
    _G.cokeline.valid_buffers[deleted_buffer._valid_index ~= #_G.cokeline.valid_buffers and deleted_buffer._valid_index + 1 or #_G.cokeline.valid_buffers - 1]

  vim.cmd(
    ("b%s"):format(
      (gl_settings.focus_on_delete == "prev" and prev_buffer.number)
        or (gl_settings.focus_on_delete == "next" and next_buffer.number)
    )
  )
end

local setup = function(settings)
  gl_settings = settings

  vim.cmd([[
  augroup cokeline_toggle
    autocmd VimEnter,BufAdd * lua require('cokeline/augroups').toggle()
  augroup END
  ]])

  if gl_settings.focus_on_delete then
    vim.cmd([[
    augroup cokeline_focus
      autocmd BufUnload *
        \ exe printf(
        \   'lua require("cokeline/augroups").focus_on_delete(%s)', expand('<abuf>')
        \ )
    augroup END
    ]])
  end
end

return {
  focus_on_delete = focus_on_delete,
  toggle = toggle,
  setup = setup,
}
