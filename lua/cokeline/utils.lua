local format = string.format
local tohex = bit.tohex

local get_hl_by_name = vim.api.nvim_get_hl_by_name

local M = {}

-- Return the table with the reversed order
function M.reverse(t)
  local rev = {}
  for i = #t, 1, -1 do
    rev[#rev + 1] = t[i]
  end
  return rev
end

-- Given a highlight group name and an attribute (foreground or background),
-- return the color set by the current colorscheme for that highlight group's
-- attribute in hexadecimal format.
function M.get_hex(hlname, attr)
  local attribute =
    attr == 'fg'
    and 'foreground'
     or 'background'

  -- TODO: not sure why this fails if I call 'get_hl_by_name' directly instead
  -- of through a pcall.
  local _, hldef = pcall(get_hl_by_name, hlname, true)
  if hldef and hldef[attribute] then
    return format('#%s', tohex(hldef[attribute], 6))
  end

  -- TODO: nvim-bufferline handles a couple of fallbacks here in case
  -- 'get_hl_by_name' doesn't find a color for the given attribute.

  return 'NONE'
end

return M
