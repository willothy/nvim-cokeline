local get_hex = require('cokeline/hlgroups').get_hex

local has_devicons, devicons = pcall(require, 'nvim-web-devicons')
local get_icon
if has_devicons then
  devicons.setup({default = true})
  get_icon = devicons.get_icon
end

local reverse = string.reverse
local insert = table.insert

local contains = vim.tbl_contains
local filter = vim.tbl_filter
local map = vim.tbl_map
local fn = vim.fn

local Buffer = {
  number = 0,
  index = 0,
  is_focused = false,
  is_modified = false,
  is_readonly = false,
  type = '',
  filename = '',
  unique_prefix = '',
  devicon = '',
  devicon_color = '',
}

local M = {}

local function get_unique_prefix(filename)
  -- Taken from github.com/famiu/feline.nvim

  local listed_buffers = fn.getbufinfo({buflisted = 1})
  local filenames = map(function(b) return b.name end, listed_buffers)
  local other_filenames = filter(
    function(f) return filename ~= f end,
    filenames
  )

  if #other_filenames == 0 then
    return fn.fnamemodify(filename, ':t')
  end

  filename = reverse(filename)
  other_filenames = map(reverse, other_filenames)

  local index = math.max(unpack(map(
    function(f)
      for i = 1, #f do
        if filename:sub(i, i) ~= f:sub(i, i) then
          return i
        end
      end
      return 1
    end,
    other_filenames
  )))

  local path_separator = '/'

  while index <= #filename do
    if filename:sub(index, index) == path_separator then
      index = index - 1
      break
    end

    index = index + 1
  end

  local aux = filename:sub(1, index)
  return reverse(aux:sub(#fn.fnamemodify(reverse(filename), ':t') + 1, #aux))
end

function Buffer:new(args)
  local buffer = {}
  setmetatable(buffer, self)
  self.__index = self

  if args.bufnr then
    buffer.number = args.bufnr
    buffer.type = vim.bo[args.bufnr].buftype
    buffer.is_focused = args.bufnr == fn.bufnr('%')
    buffer.is_modified = vim.bo[args.bufnr].modified
    buffer.is_readonly = vim.bo[args.bufnr].readonly
  end

  if args.name then
    buffer.path = args.name
  end

  if buffer.type == 'quickfix' then
    buffer.filename = '[Quickfix List]'
  elseif #buffer.path > 0 then
    buffer.filename = fn.fnamemodify(buffer.path, ':t')
  else
    buffer.filename = '[No Name]'
  end

  local name =
    buffer.type == 'terminal'
    and 'terminal'
     or fn.fnamemodify(buffer.path, ':t')
  local extension = fn.fnamemodify(buffer.path, ':e')
  local devicon, devicon_hlgroup = get_icon(name, extension)
  buffer.devicon = devicon .. ' '
  buffer.devicon_color = get_hex(devicon_hlgroup, 'fg')

  buffer.unique_prefix = get_unique_prefix(buffer.path)

  return buffer
end

function M.get_listed(order)
  local listed_buffers = fn.getbufinfo({buflisted = 1})

  if not next(order) then
    local buffers = map(function(b) return Buffer:new(b) end, listed_buffers)
    for index, buffer in ipairs(buffers) do
      buffer.index = index
    end
    return buffers
  end

  local buffers = {}
  local buffer_numbers = {}

  -- First add the buffers whose numbers are in the global 'order' table that
  -- are still listed.
  for _, number in ipairs(order) do
    for _, b in pairs(listed_buffers) do
      if b.bufnr == number then
        insert(buffers, Buffer:new(b))
        insert(buffer_numbers, number)
        break
      end
    end
  end

  -- Then add all the listed buffers whose numbers are not yet in the global
  -- 'order' table.
  for _, b in pairs(listed_buffers) do
    if not contains(buffer_numbers, b.bufnr) then
      insert(buffers, Buffer:new(b))
    end
  end

  for index, buffer in ipairs(buffers) do
    buffer.index = index
  end

  return buffers
end

return M
