local holders = require('cokeline/defaults').line_placeholders

local has_devicons, devicons = pcall(require, 'nvim-web-devicons')
if has_devicons then
  devicons.setup({default = true})
  get_icon = devicons.get_icon
end

local format = string.format
local concat = table.concat
local insert = table.insert
local vimfn = vim.fn
local fnamemodify = vim.fn.fnamemodify

local M = {}

M.Line = {
  text = ''
}

-- The Vim syntax to embed a string 'foo' in a custom highlight group 'HL' is
-- to return '%#HL#foo%*', where the closing '%*' ends *all* highlight groups
-- opened up to that point.

-- This is annoying because if one starts a highlight group called 'HLa', then
-- another one called 'HLb', there's no way to end 'HLb' without also ending
-- 'HLa'.

-- This function fixes that by taking in the text with the broken syntax and
-- the component that broke it, and it:
--   1. finds the highlight group that was active before the component;
--   2. ends it;
--   3. restarts it after the component.

-- In short, we take in '%#HLa#foo%#HLb#bar%*baz%*' and '%#HLb#bar%*'
--                       \________HLa_______/
--                                \___HLb___/
-- and we return '%#HLa#foo%*%#HLb#bar%*%#HLa#baz%*'.
--                \___HLa___/\___HLb___/\___HLa___/

local function fix_hl_syntax(text, component)
  local before, after = text:match(format(
    '(.*)%s(.*)', component:gsub('([^%w])', '%%%1')))
  local active_hlgroup = before:gsub('.*%%#([^#]*)#.*', '%1')
  return format('%s%%*%s%%#%s#%s', before, component, active_hlgroup, after)
end

function M.Line:embed_in_clickable_region(bufnr)
  self.text = format('%%%s@cokeline#handle_click@%s', bufnr, self.text)
end

function M.Line:render_devicon(path, buftype, hlgroups)
  local filename =
    buftype == 'terminal'
     and 'terminal'
      or fnamemodify(path, ':t')
  local extension = fnamemodify(path, ':e')
  local icon, _ = get_icon(filename, extension)
  local devicon = hlgroups[icon]:embed(format('%s ', icon))
  self.text = self.text:gsub(holders.devicon, devicon:gsub('%%', '%%%%'))
  self.text = fix_hl_syntax(self.text, devicon)
end

function M.Line:render_index(index)
  self.text = self.text:gsub(holders.index, index)
end

function M.Line:render_filename(path, buftype)
  local filename =
    (buftype == 'quickfix' and '[Quickfix List]')
    or (#path > 0 and fnamemodify(path, ':t'))
    or '[No Name]'
  if filename:match('%%') then
    filename = filename:gsub('%%', '%%%%%%%%')
  end
  self.text = self.text:gsub(holders.filename, filename)
end

function M.Line:render_flags(
    is_modified,
    is_readonly,
    symbol_modified,
    symbol_readonly,
    hlgroup_modified,
    hlgroup_readonly,
    flags_fmt,
    divider)

  if not (is_modified or is_readonly) then
    self.text = self.text:gsub(holders.flags, '')
    return
  end

  local symbols = {}
  if is_modified then
    insert(symbols, hlgroup_modified:embed(symbol_modified))
  end
  if is_readonly then
    insert(symbols, hlgroup_readonly:embed(symbol_readonly))
  end

  local flags = concat(symbols, divider)
  local flags_fmtd = flags_fmt:gsub(holders.flags, flags:gsub('%%', '%%%%'))
  self.text = self.text:gsub(holders.flags, flags_fmtd:gsub('%%', '%%%%'))
  self.text = fix_hl_syntax(self.text, flags)
end

function M.Line:render_close_button(bufnr, close_button_symbol)
  local close_button = format(
    '%%%s@cokeline#close_button_handle_click@%s%%%s@cokeline#handle_click@',
    bufnr,
    close_button_symbol,
    bufnr)
  self.text = self.text:gsub(
    holders.close_button, close_button:gsub('%%', '%%%%'))
end

function M.Line:new(text)
  line = {}
  setmetatable(line, self)
  self.__index = self
  if text then
    line.text = text
  end
  return line
end

return M
