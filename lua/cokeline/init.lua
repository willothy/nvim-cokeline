local augroups = require('cokeline/augroups')
local defaults = require('cokeline/defaults')
local highlights = require('cokeline/highlights')
local utils = require('cokeline/utils')
local has_devicons, devicons = pcall(require, 'nvim-web-devicons')
local fn = vim.fn
local M = {}

local function cokeline(settings)
  local titles = {}
  local listed_buffers = fn.getbufinfo({buflisted=1})
  local tags = {
    icon = '{icon}',
    index = '{index}',
    name = '{name}',
    flags = '{flags}',
  }
  for index, buffer in ipairs(listed_buffers) do
    local is_focused = buffer.bufnr == fn.bufnr('%')
    local is_modified = vim.bo[buffer.bufnr].modified
    local has_icon = has_devicons and settings.use_devicons
    local has_flags = is_modified
    local highlight = is_focused and 'CokeFocused' or 'CokeUnfocused'
    local icon = ''
    if has_icon then
      local extension = fn.fnamemodify(buffer.name, ':e')
      local raw_icon, icon_highlight =
        devicons.get_icon(buffer.name, extension, {default=true})
      icon = '%#'..icon_highlight..'#'..raw_icon..' %*'
    end
    local expands = {
      icon = icon,
      index = index,
      name = fn.fnamemodify(buffer.name, ':t'),
      flags = has_flags and ('['..(is_modified and '+' or '')..']') or ''
    }
    local title = '%#'..highlight..'# '..settings.title_format..' %*'
    for k, v in pairs(tags) do
      title = title:gsub(v, expands[k])
    end
    table.insert(titles, title)
  end
  return table.concat(titles, '')
end

-- function M.redraw()
--   vim.cmd('redrawtabline')
-- end

function M.toggle()
  local buffers = fn.getbufinfo({buflisted=1})
  vim.o.showtabline = (#buffers > 1 and 2) or 0
end

function M.setup(preferences)
  local settings = utils.update(defaults, preferences)
  augroups.setup(settings)
  highlights.setup(settings.highlights)
  function _G.cokeline() return cokeline(settings) end
  vim.o.tabline = '%!v:lua.cokeline()'
end

return M
