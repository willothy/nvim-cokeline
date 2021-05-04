local augroups = require('cokeline/augroups')
local defaults = require('cokeline/defaults')
local hilights = require('cokeline/hilights')
local format = string.format
local vimfn = vim.fn
local M = {}

local function cokeline(settings)
  local titles = {}
  local listed_buffers = vimfn.getbufinfo({buflisted = 1})

  for index, buffer in ipairs(listed_buffers) do
    local is_focused = buffer.bufnr == vimfn.bufnr('%')
    local is_modified = vim.bo[buffer.bufnr].modified
    local has_flags = is_modified
    local highlight = is_focused and 'Focused' or 'Unfocused'

    local devicon = ''
    if settings.show_devicons then
      local get_devicon = require('nvim-web-devicons').get_icon
      local extension = vimfn.fnamemodify(buffer.name, ':e')
      local raw_icon, raw_icon_highlight =
        get_devicon(buffer.name, extension, {default=true})
      -- using double percent signs to escape them for gsub
      local icon_highlight = 'Coke' .. raw_icon_highlight .. highlight
      devicon =
        '%%#'..icon_highlight..'#'..raw_icon..' %%#Coke'..highlight..'#'
    end

    local filename = vimfn.fnamemodify(buffer.name, ':t')

    local flags = ''
    if has_flags then
      flags = settings.formats.flags
    end

    local close_icon = ''
    if settings.show_close_icons then
      close_icon = format (
        '%%%%' .. '%s@cokeline#handle_close_icon_click@%s',
        buffer.bufnr,
        settings.symbols.close
      )
    end

    local modified = settings.symbols.modified

    local expands = {
      devicon = devicon,
      index = index,
      filename = filename,
      flags = flags,
      close_icon = close_icon,
      modified = modified,
    }
    local title =
      '%#Coke'..highlight..'#'
      ..' '..settings.formats.title..' '..'%*'

    for k, v in pairs(settings.placeholders) do
      title = title:gsub(v, expands[k])
    end

    if settings.handle_clicks then
      title = format (
        '%%%s@cokeline#handle_click@%s',
        buffer.bufnr,
        title
      )
    end

    table.insert(titles, title)
  end

  return table.concat(titles, settings.symbols.separator)
end

function M.toggle()
  local buffers = vimfn.getbufinfo({buflisted=1})
  vim.o.showtabline = (#buffers > 1 and 2) or 0
end

function M.setup(preferences)
  local settings = defaults.update(preferences)
  augroups.setup(settings)
  hilights.setup(settings)
  function _G.cokeline() return cokeline(settings) end
  vim.o.tabline = '%!v:lua.cokeline()'
end

return M
