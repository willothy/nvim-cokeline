local vim_filter = vim.tbl_filter
local vim_fn = vim.fn
local vim_opt = vim.opt

local gl_settings

local toggle = function()
  local listed_buffers = vim_fn.getbufinfo({buflisted = 1})
  vim_opt.showtabline = #listed_buffers > 0 and 2 or 0
end

---@param bufnr  number
local focus = function(bufnr)
  if #_G.cokeline.valid_buffers == 1 then return end

  local deleted_buffer = vim_filter(
    function(buffer) return buffer.number == bufnr end,
    _G.cokeline.valid_buffers
  )[1]
  if not deleted_buffer then return end

  ---@param buffer  Buffer
  ---@return Buffer
  local prev = function(buffer)
    return _G.cokeline.valid_buffers[
      buffer._valid_index ~= 1
      and buffer._valid_index - 1
       or 2
    ]
  end

  ---@param buffer  Buffer
  ---@return Buffer
  local next = function(buffer)
    return _G.cokeline.valid_buffers[
      buffer._valid_index ~= #_G.cokeline.valid_buffers
      and buffer._valid_index + 1
       or #_G.cokeline.valid_buffers - 1
    ]
  end

  vim.cmd(('b%s'):format(
    (gl_settings.focus_on_delete == 'prev' and prev(deleted_buffer).number)
    or (gl_settings.focus_on_delete == 'next' and next(deleted_buffer).number)
  ))
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
        \   'lua require("cokeline/augroups").focus(%s)', expand('<abuf>')
        \ )
    augroup END
    ]])
  end
end

return {
  toggle = toggle,
  focus = focus,
  setup = setup,
}
