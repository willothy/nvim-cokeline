local defaults = require('cokeline/defaults')
local augroups = require('cokeline/augroups')
local hlgroups = require('cokeline/hlgroups')
local Line = require('cokeline/lines').Line

local concat = table.concat
local insert = table.insert
local vimfn = vim.fn

local M = {}

local function cokeline(settings)
  local symbols = settings.symbols
  local lines = {}

  for i, b in ipairs(vimfn.getbufinfo({buflisted = 1})) do
    local hlgroups =
      b.bufnr == vimfn.bufnr('%')
      and settings.hlgroups.focused
       or settings.hlgroups.unfocused

    local line = Line:new(hlgroups.line:embed(settings.line_format))

    if settings.handle_clicks then
      line:embed_in_clickable_region(b.bufnr)
    end
    if settings.show_devicons then
      line:render_devicon(b.name, hlgroups.devicons)
    end
    if settings.show_indexes then
      line:render_index(i)
    end
    if settings.show_filenames then
      line:render_filename(b.name)
    end
    if settings.show_flags then
      line:render_flags(
        vim.bo[b.bufnr].modified,
        vim.bo[b.bufnr].readonly,
        hlgroups.line:embed(settings.flags_format),
        hlgroups.line:embed(settings.flags_divider),
        symbols.modified,
        symbols.readonly,
        hlgroups.modified,
        hlgroups.readonly)
    end
    if settings.show_close_buttons then
      line:render_close_button(b.bufnr, symbols.close_button)
    end
    insert(lines, line.text)
  end

  return concat(lines)
end

function M.setup(preferences)
  local settings = defaults.merge(preferences)
  augroups.setup(settings)
  settings = hlgroups.setup(settings)
  _G.cokeline = function() return cokeline(settings) end
  vim.o.showtabline = 2
  vim.o.tabline = '%!v:lua.cokeline()'
end

return M
