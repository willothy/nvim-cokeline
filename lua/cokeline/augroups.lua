local setup = function()
  vim.cmd([[
  augroup cokeline_toggle
    autocmd VimEnter,BufAdd * lua require"cokeline/buffers".toggle()
  augroup END
  ]])
end

return {
  setup = setup,
}
