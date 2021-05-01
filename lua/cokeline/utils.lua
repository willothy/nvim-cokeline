local cmd = vim.cmd
local M = {}

-- @param msg string
local function echoerr(msg)
  cmd([[echoerr "[cokeline.nvim]: ]]..msg..[["]])
end

-- @param t1 table
-- @param t2 table
function M.update(t1, t2)
  for k, v in pairs(t2) do
    if t1[k] ~= nil then
      t1[k] = v
    else
      echoerr([[Configuration option ']]..k..[[' does not exist!]])
    end
  end
  return t1
end

function M.create_augroups(augroups)
  for _, augroup in pairs(augroups) do
    cmd('augroup '..augroup.name)
    cmd('autocmd!')
    for _, aucmd in pairs(augroup.autocmds) do
      cmd('autocmd '..aucmd.event..' '..aucmd.target..' '..aucmd.command)
    end
    cmd('augroup END')
  end
end

return M
