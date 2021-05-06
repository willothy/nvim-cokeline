local concat = table.concat
local insert = table.insert
local format = string.format
local vimcmd = vim.cmd

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

function M.setup(settings)
  -- TODO
  -- BufEnter is excessive. BufAdd and BufDelete should be enough, but
  -- BufDelete is triggered before the buffer is actually unlisted, which means
  -- toggle() will count two buffers, not one. See
  -- https://neovim.io/doc/user/autocmd.html#%7Bevent%7D
  if settings.hide_when_one_buffer then
    Augroup:new(
      'cokeline_toggle',
      {
        Autocmd:new('BufEnter', '*', 'lua require"cokeline".toggle()')
      }
    )
  end
end

return M
