local cmd = vim.cmd

local M = {}

M.Hlgroup = {}

function M.Hlgroup:new(args)
  local hlgroup = {
    name = args.name,
    opts = args.opts,
  }
  setmetatable(hlgroup, self)
  self.__index = self
  hlgroup:exec()
  return hlgroup
end

function M.Hlgroup:exec()
  local opts = ''
  for k, v in pairs(self.opts) do
    opts = opts .. ('%s=%s'):format(k, v) .. ' '
  end
  -- Clear the highlight group before (re)defining it
  cmd(('highlight clear %s'):format(self.name))
  cmd(('highlight %s %s'):format(self.name, opts))
end

function M.Hlgroup:embed(text)
  return ('%%#%s#%s%%*'):format(self.name, text)
end

function M.setup(defaults)
  M.defaults = {
    focused = M.Hlgroup:new({
      name = 'CokeFocused',
      opts = {
        guifg = defaults.focused.fg,
        guibg = defaults.focused.bg,
      }
    }),

    unfocused = M.Hlgroup:new({
      name = 'CokeUnfocused',
      opts = {
        guifg = defaults.unfocused.fg,
        guibg = defaults.unfocused.bg,
      }
    }),
  }
end

return M
