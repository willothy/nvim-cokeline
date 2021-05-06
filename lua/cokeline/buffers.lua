local insert = table.insert
local vimfn = vim.fn
local vimbo = vim.bo

local M = {}

local Buffer = {
  id = 0,
  index = 0,
  path = '',
  is_focused = false,
  flags = {
    modified = false,
    readonly = false,
  },
}

function Buffer:new()
  buffer = {}
  setmetatable(buffer, self)
  self.__index = self
  return buffer
end

local function populate_from(list)
  local buffers = {}
  for i, b in ipairs(list) do
    local buffer = Buffer:new()
    buffer.id = b.bufnr
    buffer.index = i
    buffer.path = b.name
    buffer.is_focused = b.bufnr == vimfn.bufnr('%')
    buffer.flags = {
      modified = vimbo[b.bufnr].modified,
      readonly = vimbo[b.bufnr].readonly,
      -- modified = vimfn.getbufvar(b.bufnr, '&modified'),
      -- readonly = vimfn.getbufvar(b.bufnr, '&readonly'),
    }
    insert(buffers, buffer)
  end
  return buffers
end

function M.get_listed()
  local listed_buffers = vimfn.getbufinfo({buflisted = 1})
  return populate_from(listed_buffers)
end

return M
