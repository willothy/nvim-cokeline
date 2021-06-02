local format = string.format
local concat = table.concat
local insert = table.insert

local cmd = vim.cmd

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

function Autocmd:new(args)
  autocmd = {}
  setmetatable(autocmd, self)
  self.__index = self
  if args.events then
    autocmd.events = args.events
  end
  if args.target then
    autocmd.target = args.target
  end
  if args.command then
    autocmd.command = args.command
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
  cmd(augroup_fmt:format(self.name, concat(autocmds, '\n')))
end

function Augroup:new(args)
  augroup = {}
  setmetatable(augroup, self)
  self.__index = self
  if args.name then
    augroup.name = args.name
  end
  if args.autocmds then
    augroup.autocmds = args.autocmds
  end
  augroup:exec()
  return augroup
end

function M.setup(settings)
  if settings.hide_when_one_buffer then
    Augroup:new({
      name = 'cokeline_toggle',
      autocmds = {
        Autocmd:new({
          events = 'BufAdd',
          target = '*',
          command = 'lua require"cokeline".toggle()',
        }),
      },
    })
  end
end

return M
