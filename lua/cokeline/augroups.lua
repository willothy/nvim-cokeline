local M = {}

function M.setup()
  vim.cmd([[
  augroup cokeline_toggle
    autocmd VimEnter,BufAdd * lua require'cokeline'.toggle()
  augroup END
  ]])
end

return M
