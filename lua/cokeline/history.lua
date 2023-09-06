local lazy = require("cokeline.lazy")
local buffers = lazy("cokeline.buffers")

---@class Cokeline.History
---@field len integer
---@field cap integer
---@field data bufnr[]
local History = {}

---Creates a new History object
---@return Cokeline.History
function History.setup(cap)
  History.cap = cap
  History.len = 0
  History.read = 1
  History.write = 1
  History.data = {}
end

---Adds a Buffer object to the history
---@param bufnr bufnr
function History:push(bufnr)
  self.data[self.write] = bufnr
  self.write = (self.write % self.cap) + 1
  if self.len < self.cap then
    self.len = self.len + 1
  end
end

---Removes and returns the oldest Buffer object in the history
---@return Buffer|nil
function History:pop()
  if self.len == 0 then
    return nil
  end
  local bufnr = self.data[self.read]
  self.data[self.read] = nil
  self.read = (self.read % self.cap) + 1
  if bufnr then
    self.len = self.len - 1
  end
  if bufnr then
    return buffers.get_buffer(bufnr)
  end
end

---Returns a list of Buffer objects in the history,
---ordered from oldest to newest
---@return Buffer[]
function History:list()
  local list = {}
  local read = self.read
  for _ = 1, self.len do
    local buf = self.data[read]
    if buf then
      table.insert(list, buffers.get_buffer(buf))
    end
    read = (read % self.cap) + 1
  end
  return list
end

---Returns an iterator of Buffer objects in the history,
---ordered from oldest to newest
---@return fun():Buffer
function History:iter()
  local read = self.read
  return function()
    local buf = self.data[read]
    if buf then
      read = (read % self.cap) + 1
      return buffers.get_buffer(buf)
    end
  end
end

---Get a Buffer object by history index
---@param idx integer
---@return Buffer|nil
function History:get(idx)
  local buf = self.data[(self.read % self.cap) + idx + 1]
  if buf then
    return buffers.get_buffer(buf)
  end
end

---Get a Buffer object representing the last-accessed buffer (before the current one)
---@return Buffer|nil
function History:last()
  local buf = self.data[self.write == 1 and self.len or (self.write - 1)]
  if buf then
    return buffers.get_buffer(buf)
  end
end

---Returns true if the history is empty
---@return boolean
function History:is_empty()
  return self.read == self.write
end

---Returns the maximum number of buffers that can be stored in the history
---@return integer
function History:capacity()
  return self.cap
end

---Returns true if the history contains the given buffer
---@param bufnr bufnr
---@return boolean
function History:contains(bufnr)
  return vim.tbl_contains(self.data, bufnr)
end

---Returns the number of buffers in the history
---@return integer
function History:len()
  return self.len
end

return History
