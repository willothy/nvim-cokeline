local concat = table.concat
local insert = table.insert

local defaults = require('cokeline/defaults')
local augroups = require('cokeline/augroups')
local hlgroups = require('cokeline/hlgroups')
local buffers = require('cokeline/buffers')
local Title = require('cokeline/titles').Title

local M = {}

local function cokeline(settings)
  local groups = settings.hlgroups
  local symbols = settings.symbols
  local buffers = buffers.get_listed()
  local titles = {}

  for _, buffer in pairs(buffers) do
    local title = Title:new(settings.title_format)
    title:embed_in_hlgroup(groups.titles, buffer.is_focused)
    if settings.handle_clicks then
      title:embed_in_clickable_region(buffer.id)
    end
    if settings.show_devicons then
      title:render_devicon(buffer.path, buffer.is_focused, groups.devicons)
    end
    if settings.show_indexes then
      title:render_index(buffer.index)
    end
    if settings.show_filenames then
      title:render_filename(buffer.path)
    end
    if settings.show_flags then
      title:render_flags(buffer.flags, symbols.flags)
    end
    if settings.show_close_buttons then
      title:render_close_button(buffer.id, symbols.close)
    end
    insert(titles, title.title)
  end

  local separator = groups.symbols.separator:embed(symbols.separator)
  local cokeline = concat(titles, separator)
  return cokeline
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
