local defaults = require('cokeline/defaults')
local hlgroups = require('cokeline/hlgroups')
local augroups = require('cokeline/augroups')
local mappings = require('cokeline/mappings')
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
    local bopts = vim.bo[b.bufnr]

    if settings.handle_clicks then
      line:embed_in_clickable_region(b.bufnr)
    end
    if settings.show_devicons then
      line:render_devicon(b.name, bopts.buftype, hlgroups.devicons)
    end
    if settings.show_indexes then
      line:render_index(i)
    end
    if settings.show_flags then
      line:render_flags(
        bopts.modified,
        bopts.readonly,
        symbols.modified,
        symbols.readonly,
        hlgroups.modified,
        hlgroups.readonly,
        settings.flags_format,
        hlgroups.line:embed(settings.flags_divider))
    end
    if settings.show_close_buttons then
      line:render_close_button(b.bufnr, symbols.close_button)
    end
    if settings.show_filenames then
      line:render_filename(b.name, bopts.buftype)
    end
    insert(lines, line.text)
  end

  return concat(lines)
end

function M.setup(preferences)
  local settings = defaults.merge(preferences)
  settings = hlgroups.setup(settings)
  augroups.setup(settings)
  mappings.setup(settings)
  _G.cokeline = function() return cokeline(settings) end
  vim.o.showtabline = 2
  vim.o.tabline = '%!v:lua.cokeline()'
end

return M
