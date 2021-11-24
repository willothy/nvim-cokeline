local M = {}

M.setup = function()
  vim.cmd([[
  augroup cokeline_toggle
    autocmd VimEnter,BufAdd * lua require"cokeline".toggle()
  augroup END
  ]])
end

return M
