local M = {}

function M.setup(settings)
  if settings.hide_when_one_buffer then
    vim.cmd([[
    augroup cokeline_toggle
      autocmd VimEnter,BufAdd * lua require'cokeline'.toggle()
    augroup END
    ]])
  end
end

return M
