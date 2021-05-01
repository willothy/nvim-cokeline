local M = {}

function M.setup(colors)
  vim.cmd([[hi TabLineFill guibg=]]..colors.cokeline.bg)
  vim.cmd([[hi CokeFocused guibg=]]..colors.buffers.focused.bg..[[ guifg=]]..colors.buffers.focused.fg)
  vim.cmd([[hi CokeUnfocused guibg=]]..colors.buffers.unfocused.bg..[[ guifg=]]..colors.buffers.unfocused.fg)
end

return M
