local M = {}

function M.update(t1, t2)
  for k, v in pairs(t2) do
    if t1[k] == nil then
      print('ERROR')
    end
    t1[k] = v
  end
  return t1
end

function M.create_augroups(augroups)
  for _, augroup in pairs(augroups) do
    vim.cmd('augroup '..augroup.name)
    vim.cmd('autocmd!')
    for _, cmd in pairs(augroup.autocmds) do
      vim.cmd('autocmd '..cmd.event..' '..cmd.target..' '..cmd.command)
    end
    vim.cmd('augroup END')
  end
end

return M
