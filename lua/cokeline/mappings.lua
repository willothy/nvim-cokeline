local keymap = vim.api.nvim_set_keymap

local M = {}

local plugmap = function(args)
  keymap('n', args.lhs, args.rhs, {noremap = true, silent = true})
end

function M.setup()
  local lhs_fmt = '<Plug>(cokeline-%s-%s)'
  local rhs_fmt = '<Cmd>lua require"cokeline".%s({%s = %s})<CR>'

  for _, action in pairs({'focus', 'switch'}) do
    for _, step in pairs({'1', '-1'}) do
      plugmap({
        lhs = lhs_fmt:format(action, step == '1' and 'next' or 'prev'),
        rhs = rhs_fmt:format(action, 'step', step),
      })
    end

    for target = 1,20 do
      plugmap({
        lhs = lhs_fmt:format(action, target),
        rhs = rhs_fmt:format(action, 'target', target),
      })
    end
  end
end

return M
