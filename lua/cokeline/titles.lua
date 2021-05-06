local format = string.format
local concat = table.concat
local insert = table.insert
local vimfn = vim.fn

local placeholders = require('cokeline/defaults').title_placeholders

local M = {}

M.Title = {
  title = ''
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

local function fix_hl_syntax(title, component)
  local before, after = title:match(format(
    '(.*)%s(.*)',
    component:gsub('([^%w])', '%%%1')
  ))
  local active_hl = before:gsub('.*%%#([^#]*)#.*', '%1')
  return format('%s%%*%s%%#%s#%s', before, component, active_hl, after)
end

function M.Title:embed_in_hlgroup(titles_grp, is_focused)
  local hlgroup =
    is_focused
    and titles_grp.focused
     or titles_grp.unfocused
  self.title = hlgroup:embed(self.title)
end

function M.Title:embed_in_clickable_region(id)
  local fmt = '%%%s@cokeline#handle_clicks@%s'
  self.title = fmt:format(id, self.title)
end

function M.Title:render_devicon(path, is_focused, devicons_grp)
  local ext = vimfn.fnamemodify(path, ':e')
  local get_icon = require('nvim-web-devicons').get_icon
  local icon, _ = get_icon(path, ext, {default = true})
  local hlgroup =
    is_focused
    and devicons_grp[icon].focused
     or devicons_grp[icon].unfocused
  local devicon = hlgroup:embed(format('%s ', icon))
  self.title = self.title:gsub(
    placeholders.devicon,
    devicon:gsub('%%', '%%%%')
  )
  self.title = fix_hl_syntax(self.title, devicon)
end

function M.Title:render_index(index)
  self.title = self.title:gsub(placeholders.index, index)
end

function M.Title:render_filename(path)
  local filename = vimfn.fnamemodify(path, ':t')
  self.title = self.title:gsub(placeholders.filename, filename)
end

function M.Title:render_flags(flags, symbols)
  local active_symbols = {}
  for flag, is_active in pairs(flags) do
    if is_active then
      insert(active_symbols, symbols[flag])
    end
  end
  local active_flags =
    #active_symbols > 0
    and format('[%s]', concat(active_symbols, ','))
     or ''
  self.title = self.title:gsub(placeholders.flags, active_flags)
end

function M.Title:render_close_button(id, close_symbol)
  local fmt = '%%%s@cokeline#close_button_handle_clicks@%s'
  local close_button = fmt:format(id, close_symbol):gsub('%%', '%%%%')
  self.title = self.title:gsub(placeholders.close_button, close_button)
end

function M.Title:new(str)
  title = {}
  setmetatable(title, self)
  self.__index = self
  if str then
    title.title = format(' %s ', str)
  end
  return title
end

return M
