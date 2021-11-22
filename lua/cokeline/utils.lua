local echo = vim.api.nvim_echo
local fn = vim.fn

local M = {}

-- Formats an error message
---@param msg string
M.echoerr = function(msg)
  echo({{('[cokeline.nvim]: %s'):format(msg), 'ErrorMsg'}}, true, {})
end

-- Given a highlight group name and an attribute (foreground or background),
-- return the color set by the current colorscheme for that highlight group's
-- attribute in hexadecimal format.
---@param hlgroup_name string
---@param attr string
---@return string
M.get_hex = function(hlgroup_name, attr)
  local hlgroup_ID = fn.synIDtrans(fn.hlID(hlgroup_name))
  local hex = fn.synIDattr(hlgroup_ID, attr)
  return (hex ~= '') and hex or 'NONE'
end

return M
