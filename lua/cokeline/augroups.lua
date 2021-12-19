local vim_fn = vim.fn
local vim_opt = vim.opt

local toggle = function()
  local listed_buffers = vim_fn.getbufinfo({buflisted = 1})
  vim_opt.showtabline = #listed_buffers > 0 and 2 or 0
end

local setup = function()
  vim.cmd([[
  augroup cokeline_toggle
    autocmd VimEnter,BufAdd * lua require('cokeline/augroups').toggle()
  augroup END
  ]])
end

return {
  toggle = toggle,
  setup = setup,
}
