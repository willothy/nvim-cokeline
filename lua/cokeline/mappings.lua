local keymap = vim.api.nvim_set_keymap

---@param lhs  string
---@param rhs  string
local plugmap = function(lhs, rhs)
  keymap('n', lhs, rhs, {noremap = true, silent = true})
end

local setup = function()
  for i=1,20 do
    plugmap(
      ('<Plug>(cokeline-switch-%s)'):format(i),
      ('<Cmd>lua require"cokeline/buffers".switch_by_index(%s)<CR>'):format(i)
    )
    plugmap(
      ('<Plug>(cokeline-focus-%s)'):format(i),
      ('<Cmd>lua require"cokeline/buffers".focus_by_index(%s)<CR>'):format(i)
    )
  end

  plugmap(
    '<Plug>(cokeline-switch-prev)',
    '<Cmd>lua require"cokeline/buffers".switch_by_step(-1)<CR>'
  )
  plugmap(
    '<Plug>(cokeline-switch-next)',
    '<Cmd>lua require"cokeline/buffers".switch_by_step(1)<CR>'
  )
  plugmap(
    '<Plug>(cokeline-focus-prev)',
    '<Cmd>lua require"cokeline/buffers".focus_by_step(-1)<CR>'
  )
  plugmap(
    '<Plug>(cokeline-focus-next)',
    '<Cmd>lua require"cokeline/buffers".focus_by_step(1)<CR>'
  )
end

return {
  setup = setup,
}
