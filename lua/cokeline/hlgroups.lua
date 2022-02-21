local tbl_concat = table.concat

local vim_cmd = vim.cmd

---@diagnostic disable: duplicate-doc-class

---@alias hexcolor  string
---@alias attr  string

---@class Hl
---@field fg  hexcolor | fun(buffer: Buffer): hexcolor | nil
---@field bg  hexcolor | fun(buffer: Buffer): hexcolor | nil
---@field style  attr | fun(buffer: Buffer): attr | nil

---@class Hlgroup
---@field name  string
---@field guifg  hexcolor
---@field guibg  hexcolor
---@field gui  attr

---@param hlgroup  Hlgroup
local hlgroup_exec = function(hlgroup)
  local gui_options = tbl_concat({
    ("guifg=%s"):format(hlgroup.guifg),
    ("guibg=%s"):format(hlgroup.guibg),
    ("gui=%s"):format(hlgroup.gui),
  }, " ")
  -- Clear the highlight group before (re)defining it.
  vim_cmd(("highlight clear %s"):format(hlgroup.name))
  vim_cmd(("highlight %s %s"):format(hlgroup.name, gui_options))
end

---@param hlgroup  Hlgroup
---@param str  string
---@return string
local embed_in_hlgroup = function(hlgroup, str)
  return ("%%#%s#%s%%*"):format(hlgroup.name, str)
end

---@param name  string
---@param guifg  hexcolor
---@param guibg  hexcolor
---@param gui  attr
---@return Hlgroup
local new_hlgroup = function(name, guifg, guibg, gui)
  local hlgroup = {
    name = name,
    guifg = guifg,
    guibg = guibg,
    gui = gui,
  }
  hlgroup_exec(hlgroup)
  return hlgroup
end

return {
  embed_in_hlgroup = embed_in_hlgroup,
  new_hlgroup = new_hlgroup,
}
