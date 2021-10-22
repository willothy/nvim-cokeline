local diagnostics = require('cokeline/diagnostics')

local has_devicons, devicons = pcall(require, 'nvim-web-devicons')

local insert = table.insert

local contains = vim.tbl_contains
local split = vim.split
local map = vim.tbl_map
local fn = vim.fn

local Buffer = {
  number = 0,
  index = 0,
  type = '',
  filetype = '',
  is_focused = false,
  is_modified = false,
  is_readonly = false,
  path = '',
  filename = '',
  unique_prefix = '',
  devicon = {
    icon = '',
    color = '',
  },
  __is_valid = true,
  __is_shown = true,
}

local M = {}

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

  for i, _ in ipairs(paths) do
    for j=i+1,#paths do
      local k = 1
      while paths[i][k] == paths[j][k] do
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

function Buffer:new(b, index)
  local buffer = {}
  setmetatable(buffer, self)
  self.__index = self

  buffer.filetype = vim.bo[b.bufnr].filetype
  -- vim.bo[b.bufnr].filetype doesn't work for netrw buffers.
  -- Try nvim . -> :ls. The bufnr should be 1 but :lua
  -- print(vim.bo[1].filetype) returns an empty string (however :lua
  -- print(vim.bo[0].filetype) works for some reason??).
  if b.variables and b.variables.netrw_browser_active then
    buffer.filetype = 'netrw'
  end

  buffer.__is_valid = buffer.filetype ~= 'netrw'

  if not buffer.__is_valid then
    return buffer
  end

  buffer.index = index
  buffer.number = b.bufnr
  buffer.type = vim.bo[b.bufnr].buftype
  buffer.is_focused = (b.bufnr == fn.bufnr('%'))
  buffer.is_modified = vim.bo[b.bufnr].modified
  buffer.is_readonly = vim.bo[b.bufnr].readonly
  buffer.path = b.name

  if buffer.type == 'quickfix' then
    buffer.filename = '[Quickfix List]'
  elseif #buffer.path > 0 then
    buffer.filename = fn.fnamemodify(buffer.path, ':t')
  else
    buffer.filename = '[No Name]'
  end

  if has_devicons then
    local name =
      buffer.type == 'terminal'
      and 'terminal'
       or fn.fnamemodify(buffer.path, ':t')
    local extension = fn.fnamemodify(buffer.path, ':e')
    local icon, color =
      devicons.get_icon_color(name, extension, {default = true})
    buffer.devicon = {
      icon = icon .. ' ',
      color = color,
    }
  else
    buffer.devicon = {
      icon = '',
      color = '',
    }
  end

  if vim.diagnostic or vim.lsp then
    buffer.lsp = diagnostics.get_status(buffer.number)
  else
    buffer.lsp = {
      errors = 0,
      warnings = 0,
      infos = 0,
      hints = 0,
    }
  end

  buffer.__is_shown = (not user_filter) or user_filter(buffer)

  return buffer
end

function M.get_buffers(order)
  local listed_buffers = fn.getbufinfo({buflisted = 1})
  local buffers = {}
  local index = 1

  if not next(order) then
    for _, b in ipairs(listed_buffers) do
      local buffer = Buffer:new(b, index)
      if buffer.__is_valid then
        insert(buffers, buffer)
        if buffer.__is_shown then
          index = index + 1
        end
      end
    end
    return compute_unique_prefixes(buffers)
  end

  local buffer_numbers = {}

  -- First add the buffers whose numbers are in the global 'order' table that
  -- are still listed.
  for _, number in ipairs(order) do
    for _, b in pairs(listed_buffers) do
      if b.bufnr == number then
        local buffer = Buffer:new(b, index)
        if buffer.__is_valid then
          insert(buffers, buffer)
          insert(buffer_numbers, number)
          if buffer.__is_shown then
            index = index + 1
          end
          break
        end
      end
    end
  end

  -- Then add all the listed buffers whose numbers are not yet in the global
  -- 'order' table.
  for _, b in pairs(listed_buffers) do
    if not contains(buffer_numbers, b.bufnr) then
      local buffer = Buffer:new(b, index)
      if buffer.__is_valid then
        insert(buffers, buffer)
        if buffer.__is_shown then
          index = index + 1
        end
      end
    end
  end

  return compute_unique_prefixes(buffers)
end

function M.setup(settings)
  user_filter = settings.filter
end

return M
