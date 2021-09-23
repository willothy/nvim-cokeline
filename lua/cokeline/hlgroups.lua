local format = string.format
local cmd = vim.cmd

local M = {}

M.Hlgroup = {
  name = '',
  opts = {
    gui = nil,
    guifg = nil,
    guibg = nil,
  },
}

function M.Hlgroup:embed(text)
  return format('%%#%s#%s%%*', self.name, text)
end

function M.Hlgroup:exec()
  local opts = ''
  for k, v in pairs(self.opts) do
    opts = opts .. format('%s=%s', k, v) .. ' '
  end
  cmd(format('highlight! %s %s', self.name, opts))
end

function M.Hlgroup:new(args)
  local hlgroup = {}
  setmetatable(hlgroup, self)
  self.__index = self
  hlgroup.name = args.name
  hlgroup.opts = args.opts
  hlgroup:exec()
  return hlgroup
end

return M
