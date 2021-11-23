local keymap = vim.api.nvim_set_keymap

local M = {}

local plugmap = function(lhs, rhs)
  keymap('n', lhs, rhs, {noremap = true, silent = true})
end

function M.setup()
  plugmap(
    '<Plug>(cokeline-switch-prev)',
    '<Cmd>lua require"cokeline".switch_by_step(-1)<CR>'
  )
  plugmap(
    '<Plug>(cokeline-switch-next)',
    '<Cmd>lua require"cokeline".switch_by_step(1)<CR>'
  )
  plugmap(
    '<Plug>(cokeline-focus-prev)',
    '<Cmd>lua require"cokeline".focus_by_step(-1)<CR>'
  )
  plugmap(
    '<Plug>(cokeline-focus-next)',
    '<Cmd>lua require"cokeline".focus_by_step(1)<CR>'
  )

  for i=1,20 do
    plugmap(
      ('<Plug>(cokeline-switch-%s)'):format(i),
      ('<Cmd>lua require"cokeline".switch_by_index(%s)<CR>'):format(i)
    )
    plugmap(
      ('<Plug>(cokeline-focus-%s)'):format(i),
      ('<Cmd>lua require"cokeline".focus_by_index(%s)<CR>'):format(i)
    )
  end
end

return M
