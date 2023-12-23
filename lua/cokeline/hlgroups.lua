local M = {}

-- These functions are called a LOT.
-- Cache the results to avoid repeat API calls
local cache = {
  hex = {},
  groups = {},
}

---Clears the hlgroup cache.
---@private
function M._cache_clear()
  cache.groups = {}
end

---@param rgb integer
---@return string hex
function M.hex(rgb)
  if cache.hex[rgb] then
    return cache.hex[rgb]
  end
  local band, lsr = bit.band, bit.rshift

  local r = lsr(band(rgb, 0xff0000), 16)
  local g = lsr(band(rgb, 0x00ff00), 8)
  local b = band(rgb, 0x0000ff)

  local res = ("#%02x%02x%02x"):format(r, g, b)
  cache.hex[rgb] = res
  return res
end

function M.get_hl(name)
  if cache.groups[name] then
    return cache.groups[name]
  end
  local hl = vim.api.nvim_get_hl(0, { name = name })
  if not hl then
    return
  end
  if hl.fg and type(hl.fg) == "number" then
    hl.fg = M.hex(hl.fg)
  end
  if hl.bg and type(hl.bg) == "number" then
    hl.bg = M.hex(hl.bg)
  end
  if hl.sp and type(hl.sp) == "number" then
    hl.sp = M.hex(hl.sp)
  end
  cache.groups[name] = hl
  return hl
end

function M.get_hl_attr(name, attr)
  if cache.groups[name] and cache.groups[name][attr] then
    return cache.groups[name][attr]
  end
  local hl = M.get_hl(name)
  if not hl then
    return
  end
  return hl[attr]
end

---@class Hlgroup
---@field name  string
---@field gui   string
---@field guifg string
---@field guibg string
local Hlgroup = {}
Hlgroup.__index = Hlgroup

---Sets the highlight group, then returns a new `Hlgroup` table.
---@param name  string
---@param fg string
---@param bg string | nil
---@param sp string | nil
---@param gui_attrs table<string, bool>
---@return Hlgroup
Hlgroup.new = function(name, fg, bg, sp, gui_attrs)
  local hlgroup = {}
  if fg ~= "NONE" and vim.fn.hlexists(fg) == 1 then
    hlgroup.fg = M.get_hl_attr(fg, "fg")
  else
    hlgroup.fg = fg or "NONE"
  end
  if bg ~= "NONE" and vim.fn.hlexists(bg) == 1 then
    hlgroup.bg = M.get_hl_attr(bg, "bg")
  else
    hlgroup.bg = bg or "NONE"
  end
  if sp and sp ~= "NONE" and vim.fn.hlexists(sp) == 1 then
    hlgroup.sp = M.get_hl_attr(sp, "sp")
  else
    hlgroup.sp = sp or "NONE"
  end

  for attr, val in pairs(gui_attrs) do
    if type(val) == "boolean" then
      hlgroup[attr] = val
    end
  end

  hlgroup.default = false
  vim.api.nvim_set_hl(0, name, hlgroup)

  hlgroup.name = name
  setmetatable(hlgroup, Hlgroup)
  return hlgroup
end

---Using already existing highlight group, returns a new `Hlgroup` table.
---@param name  string
---@return Hlgroup
Hlgroup.new_existing = function(name)
  local hlgroup = {
    name = name,
  }
  setmetatable(hlgroup, Hlgroup)
  return hlgroup
end

---Embeds some text in a highlight group.
---@param self Hlgroup
---@param text string
---@return string
Hlgroup.embed = function(self, text)
  return ("%%#%s#%s%%*"):format(self.name, text)
end

M.Hlgroup = Hlgroup

return M
