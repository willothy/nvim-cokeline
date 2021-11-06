local echo = vim.api.nvim_echo
local fn = vim.fn

local M = {}

-- Formats an error message
function M.echoerr(msg)
  echo({{('[cokeline.nvim]: %s'):format(msg), 'ErrorMsg'}}, true, {})
end

-- Given a highlight group name and an attribute (foreground or background),
-- return the color set by the current colorscheme for that highlight group's
-- attribute in hexadecimal format.
function M.get_hex(hlgroup_name, attr)
  local hlgroup_ID = fn.synIDtrans(fn.hlID(hlgroup_name))
  local hex = fn.synIDattr(hlgroup_ID, attr)
  return (hex ~= '') and hex or 'NONE'
end

-- Taken from http://lua-users.org/wiki/CopyTable
function M.deepcopy(orig, copies)
  copies = copies or {}
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
    if copies[orig] then
      copy = copies[orig]
    else
      copy = {}
      copies[orig] = copy
      for orig_key, orig_value in next, orig, nil do
          copy[M.deepcopy(orig_key, copies)] = M.deepcopy(orig_value, copies)
      end
      setmetatable(copy, M.deepcopy(getmetatable(orig), copies))
    end
  else
    -- number, string, boolean, etc
    copy = orig
  end
  return copy
end

return M
