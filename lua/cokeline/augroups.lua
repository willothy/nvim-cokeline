local concat = table.concat
local insert = table.insert
local format = string.format
local vimcmd = vim.cmd

local M = {}

local Autocmd = {
  events = '',
  target = '',
  command = '',
}

local Augroup = {
  name = '',
  autocmds = {},
}

function Autocmd:new(events, target, command)
  autocmd = {}
  setmetatable(autocmd, self)
  self.__index = self
  if events then
    autocmd.events = events
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
    insert(autocmds, autocmd_fmt:format(cmd.events, cmd.target, cmd.command))
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

function M.setup(settings)
  if settings.hide_when_one_buffer then
    Augroup:new(
      'cokeline_toggle',
      {
        Autocmd:new('BufAdd', '*', 'lua require"cokeline".toggle()'),
      }
    )
  end
end

return M
