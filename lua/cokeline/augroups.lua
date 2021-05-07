local concat = table.concat
local insert = table.insert
local format = string.format
local vimcmd = vim.cmd
local vimfn = vim.fn

local M = {}

local Autocmd = {
  event = '',
  target = '',
  command = '',
}

local Augroup = {
  name = '',
  autocmds = {},
}

function Autocmd:new(event, target, command)
  autocmd = {}
  setmetatable(autocmd, self)
  self.__index = self
  if event then
    autocmd.event = event
  end
  if target then
    autocmd.target = target
  end
  if command then
    autocmd.command = command
  end
  return autocmd
end

function Augroup:exec()
  local augroup_fmt = [[
    augroup %s
    autocmd!
    %s
    augroup END
  ]]
  local autocmd_fmt = 'autocmd %s %s %s'
  local autocmds = {}
  for _, cmd in pairs(self.autocmds) do
    insert(autocmds, autocmd_fmt:format(cmd.event, cmd.target, cmd.command))
  end
  vimcmd(augroup_fmt:format(self.name, concat(autocmds, '\n')))
end

function Augroup:new(name, autocmds)
  augroup = {}
  setmetatable(augroup, self)
  self.__index = self
  if name then
    augroup.name = name
  end
  if autocmds then
    augroup.autocmds = autocmds
  end
  augroup:exec()
  return augroup
end

-- We take in the 'event_type' parameter because BufDelete is triggered
-- *before* a buffer is actually unlisted, so if there are two buffers and one
-- gets deleted, 'getbufinfo' will still return two buffers when that event is
-- triggered.
function M.toggle(event_type)
  local buffers = vimfn.getbufinfo({buflisted = 1})
  local threshold =
    (event_type == 'add' and 1)
    or (event_type == 'delete' and 2)
  vim.o.showtabline = (#buffers > threshold and 2) or 0
end

function M.setup(settings)
  if settings.hide_when_one_buffer then
    Augroup:new(
      'cokeline_toggle',
      {
        Autocmd:new('VimEnter,BufAdd', '*',
                      'lua require"cokeline/augroups".toggle("add")'),
        Autocmd:new('BufDelete', '*',
                      'lua require"cokeline/augroups".toggle("delete")')
      }
    )
  end
end

return M
