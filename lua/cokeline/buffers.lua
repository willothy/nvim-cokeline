local diagnostics = require('cokeline/diagnostics')

local has_devicons, devicons = pcall(require, 'nvim-web-devicons')

local insert = table.insert

local contains = vim.tbl_contains
local filter = vim.tbl_filter
local split = vim.split
local map = vim.tbl_map
local fn = vim.fn

local M = {}

local Buffer = {}
local user_filter

local compute_unique_prefixes = function(buffers)
  local paths
  local path_separator

  if fn.has('win32') == 0 then
    path_separator = '/'
    paths = map(function(b)
      return fn.reverse(split(b.path, '/'))
    end, buffers)
  else
    path_separator = '\\'
    paths = map(function(b)
      return fn.reverse(split(b.path:gsub('/', '\\'), '\\'))
    end, buffers)
  end

  local prefixes = map(function() return {} end, buffers)

  for i=1,#paths do
    for j=i+1,#paths do
      local k = 1
      while paths[i][k] == paths[j][k] and paths[i][k] do
        k = k + 1
        prefixes[i][k - 1] = prefixes[i][k - 1] or paths[i][k]
        prefixes[j][k - 1] = prefixes[j][k - 1] or paths[j][k]
      end
      if k ~= 1 then
        prefixes[i][k - 1] = prefixes[i][k - 1] or paths[i][k]
        prefixes[j][k - 1] = prefixes[j][k - 1] or paths[j][k]
      end
    end
  end

  for i, buffer in ipairs(buffers) do
    buffer.unique_prefix =
      (#prefixes[i] == #paths[i] and path_separator or '')
      .. fn.join(fn.reverse(prefixes[i]), path_separator)
      .. (#prefixes[i] > 0 and path_separator or '')
  end

  return buffers
end

function Buffer:new(b)
  local buffer = {
    -- Exposed to the users
    number = b.bufnr,
    index = 0,
    type = vim.bo[b.bufnr].buftype,
    filetype = vim.bo[b.bufnr].filetype,
    is_focused = (b.bufnr == fn.bufnr('%')),
    is_modified = vim.bo[b.bufnr].modified,
    is_readonly = vim.bo[b.bufnr].readonly,
    path = b.name,
    filename = '',
    unique_prefix = '',
    devicon = {
      icon = '',
      color = '',
    },
    lsp = {
      errors = 0,
      warnings = 0,
      infos = 0,
      hints = 0,
    },
    -- Used internally
    __is_valid = true,
    __is_shown = true,
  }
  setmetatable(buffer, self)
  self.__index = self

  -- vim.bo[b.bufnr].filetype doesn't work for netrw buffers.
  -- Try nvim . -> :ls. The bufnr should be 1 but :lua
  -- print(vim.bo[1].filetype) returns an empty string (however :lua
  -- print(vim.bo[0].filetype) works for some reason??).
  if b.variables and b.variables.netrw_browser_active then
    buffer.filetype = 'netrw'
  end

  buffer.filename =
    (buffer.type == 'quickfix' and 'quickfix')
    or (#buffer.path > 0 and fn.fnamemodify(buffer.path, ':t'))
    or '[No Name]'

  if has_devicons then
    local name = (buffer.type == 'terminal') and 'terminal' or buffer.filename
    local ext = fn.fnamemodify(buffer.path, ':e')
    local icon, color = devicons.get_icon_color(name, ext, {default = true})
    buffer.devicon = {
      icon = icon .. ' ',
      color = color,
    }
  end

  if vim.diagnostic or vim.lsp then
    buffer.lsp = diagnostics.get_status(buffer.number)
  end

  buffer.__is_valid = (buffer.filetype ~= 'netrw')
  buffer.__is_shown = (not user_filter) or user_filter(buffer)

  return buffer
end

function M.get_buffers(order)
  local listed_buffers = {}
  for _, b in pairs(fn.getbufinfo({buflisted = 1})) do
    listed_buffers[b.bufnr] = b
  end

  -- First add all the buffers whose numbers are already in the `order` table.
  local old_buffers = {}
  for _, number in pairs(order) do
    insert(old_buffers, listed_buffers[number])
  end

  -- Then add all the buffers whose numbers are not yet in the `order` table.
  local new_buffers = filter(function(b)
    return not contains(order, b.bufnr)
  end, listed_buffers)

  local buffers = {
    order = {},
    valid = {},
    visible = {},
  }
  local index = 1

  for i=1,(#old_buffers + #new_buffers) do
    local b = old_buffers[i] or new_buffers[i - #old_buffers]
    local buffer = Buffer:new(b)
    buffer.index = index
    if buffer.__is_valid then
      insert(buffers.order, buffer.number)
      insert(buffers.valid, buffer)
      if buffer.__is_shown then
        index = index + 1
      end
    end
  end

  buffers.valid = compute_unique_prefixes(buffers.valid)
  buffers.visible = filter(function(b) return b.__is_shown end, buffers.valid)

  return buffers
end

function M.setup(settings)
  user_filter = settings.filter
end

return M
