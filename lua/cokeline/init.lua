local concat = table.concat
local insert = table.insert
local vimfn = vim.fn

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
  -- return '%#CokeTitleFocused# %#CokeDevIconNixFocused# %*1: default.nix %*'
  -- return '%#CokeTitleFocused# %*%#CokeDevIconNixFocused# %*%#CokeTitleFocused#1: default.nix %*'
  return cokeline
end

-- local function cokeline(settings)
--   local titles = {}
--   local listed_buffers = vimfn.getbufinfo({buflisted = 1})

--   for index, buffer in ipairs(listed_buffers) do
--     local is_focused = buffer.bufnr == vimfn.bufnr('%')
--     local is_modified = vim.bo[buffer.bufnr].modified
--     local has_flags = is_modified
--     local highlight = is_focused and 'Focused' or 'Unfocused'

--     local devicon = ''
--     if settings.show_devicons then
--       local get_devicon = require('nvim-web-devicons').get_icon
--       local extension = vimfn.fnamemodify(buffer.name, ':e')
--       local raw_icon, raw_icon_highlight =
--         get_devicon(buffer.name, extension, {default=true})
--       -- using double percent signs to escape them for gsub
--       local icon_highlight = 'Coke' .. raw_icon_highlight .. highlight
--       devicon =
--         '%%#'..icon_highlight..'#'..raw_icon..' %%#Coke'..highlight..'#'
--     end

--     local filename = vimfn.fnamemodify(buffer.name, ':t')

--     local flags = ''
--     if has_flags then
--       flags = settings.formats.flags
--     end

--     local close_icon = ''
--     if settings.show_close_icons then
--       close_icon = format (
--         '%%%%' .. '%s@cokeline#close_icon_handle_clicks@%s',
--         buffer.bufnr,
--         settings.symbols.close
--       )
--     end

--     local modified = settings.symbols.modified

--     local expands = {
--       devicon = devicon,
--       index = index,
--       filename = filename,
--       flags = flags,
--       close_icon = close_icon,
--       modified = modified,
--     }
--     local title =
--       '%#Coke'..highlight..'#'
--       ..' '..settings.title_format..' '..'%*'

--     for k, v in pairs(settings.placeholders) do
--       title = title:gsub(v, expands[k])
--     end

--     if settings.handle_clicks then
--       title = format (
--         '%%%s@cokeline#handle_clicks@%s',
--         buffer.bufnr,
--         title
--       )
--     end

--     table.insert(titles, title)
--   end

--   return table.concat(titles, settings.symbols.separator)
-- end

function M.toggle()
  local buffers = vimfn.getbufinfo({buflisted = 1})
  vim.o.showtabline = (#buffers > 1 and 2) or 0
end

function M.setup(preferences)
  local settings = defaults.merge(preferences)
  augroups.setup(settings)
  settings = hlgroups.setup(settings)
  _G.cokeline = function() return cokeline(settings) end
  vim.o.tabline = '%!v:lua.cokeline()'
end

return M
