local format = string.format
local concat = table.concat
local insert = table.insert
local tohex = bit.tohex

local get_hl_by_name = vim.api.nvim_get_hl_by_name
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
  local highlight_fmt = 'highlight! %s %s'
  local opt_fmt = '%s=%s'
  local opts = {}
  for k, v in pairs(self.opts) do
    insert(opts, opt_fmt:format(k, v))
  end
  cmd(highlight_fmt:format(self.name, concat(opts, ' ')))
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

-- Given a highlight group name and an attribute (either 'fg' for the
-- foreground or 'bg' for the background), return the color set by the current
-- colorscheme for that particular attribute in hexadecimal format.
function M.get_hex(hlgroup, attribute)
  assert(attribute == 'fg' or attribute == 'bg')
  attribute =
    attribute == 'fg'
    and 'foreground'
     or 'background'

  -- TODO: not sure why this fails if I call the 'get_hl_by_name' function
  -- directly instead of through a pcall.
  local _, hldef = pcall(get_hl_by_name, hlgroup, true)
  if hldef and hldef[attribute] then
    return format('#%s', tohex(hldef[attribute], 6))
  end

  -- TODO: nvim-bufferline handles a couple of fallbacks here in case
  -- 'get_hl_by_name' doesn't find a color for the given attribute.

  return 'NONE'
end

return M
