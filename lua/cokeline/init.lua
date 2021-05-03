local augroups = require('cokeline/augroups')
local defaults = require('cokeline/defaults')
local hilights = require('cokeline/hilights')

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
    local highlight = is_focused and 'Focused' or 'Unfocused'
    local icon = ''
    if has_icon then
      local extension = fn.fnamemodify(buffer.name, ':e')
      local raw_icon, raw_icon_highlight =
        devicons.get_icon(buffer.name, extension, {default=true})
      -- using double percent signs to escape them for gsub
      local icon_highlight = 'Coke' .. raw_icon_highlight .. highlight
      icon = '%%#'..icon_highlight..'#'..raw_icon..' %%#Coke'..highlight..'#'
    end
    local expands = {
      icon = icon,
      index = index,
      name = fn.fnamemodify(buffer.name, ':t'),
      flags = has_flags and ('['..(is_modified and '+' or '')..']') or ''
    }
    local title = '%#Coke'..highlight..'# '..settings.title_format..' %*'
    for k, v in pairs(tags) do
      title = title:gsub(v, expands[k])
    end
    table.insert(titles, title)
  end
  -- print(table.concat(titles, ''))
  -- return '%#CokeFocused# %#DevIconNix#ab %#CokeFocused#1: default.nix %*'
  --   .. '%#CokeUnfocused# %#DevIconNix#ab %#CokeUnfocused#2: default.nix %*'
  return table.concat(titles, '')
end

function M.toggle()
  local buffers = fn.getbufinfo({buflisted=1})
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
