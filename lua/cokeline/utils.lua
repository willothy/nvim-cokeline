local echo = vim.api.nvim_echo
local fn = vim.fn

local M = {}

---Returns the color set by the current colorscheme for the `attr` attribute of
---the `hlgroup_name` highlight group in hexadecimal format.
---@param hlgroup_name  string
---@param attr          '"fg"'|'"bg"'
---@return string
M.get_hex = function(hlgroup_name, attr)
  local hlgroup_ID = fn.synIDtrans(fn.hlID(hlgroup_name))
  local hex = fn.synIDattr(hlgroup_ID, attr)
  return (hex ~= '') and hex or 'NONE'
end

---Formats an error message.
---@param msg string
local echoerr = function(msg)
  echo({{('[cokeline.nvim]: %s'):format(msg), 'ErrorMsg'}}, true, {})
end

---Checks if `t` is a list table.
---@param t table
---@return boolean
local is_list_table = function(t)
  return t[1] and true or false
end

---Updates the table `t1` with values from `t2`, printing an error message if
---a value in `t2` is not defined in `t1`.
---@param t1 table
---@param t2 table
---@return table
M.update = function(t1, t2)
  local updated = t1
  for k, v in pairs(t2) do
    if t1[k] == nil then
      echoerr(('Configuration option "%s" does not exist!'):format(k))
    else
      updated[k] =
        (type(v) == 'table' and not is_list_table(v))
        and M.update(t1[k], v)
         or v
    end
  end
  return updated
end

return M
