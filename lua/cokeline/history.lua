local lazy = require("cokeline.lazy")
local buffers = lazy("cokeline.buffers")

---@class Cokeline.History
---@field _len integer
---@field _cap integer
---@field _data bufnr[]
local History = {
  _len = 0,
  _cap = 4,
  _data = {},
  _read = 1,
  _write = 1,
}

---Creates a new History object
---@return Cokeline.History
function History.setup(cap)
  History._cap = cap
  return History
end

---Adds a Buffer object to the history
---@param bufnr bufnr
function History:push(bufnr)
  self._data[self._write] = bufnr
  self._write = (self._write % self._cap) + 1
  if self._len < self._cap then
    self._len = self._len + 1
  end
end

---Removes and returns the oldest Buffer object in the history
---@return Buffer|nil
function History:pop()
  if self._len == 0 then
    return nil
  end
  local bufnr = self._data[self._read]
  self._data[self._read] = nil
  self._read = (self._read % self._cap) + 1
  if bufnr then
    self._len = self._len - 1
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
  local read = self._read
  for _ = 1, self._len do
    local buf = self._data[read]
    if buf then
      table.insert(list, buffers.get_buffer(buf))
    end
    read = (read % self._cap) + 1
  end
  return list
end

---Returns an iterator of Buffer objects in the history,
---ordered from oldest to newest
---@return fun():Buffer?
function History:iter()
  local read = self._read
  return function()
    local buf = self._data[read]
    if buf then
      read = read + 1
      return buffers.get_buffer(buf)
    end
  end
end

---Get a Buffer object by history index
---@param idx integer
---@return Buffer|nil
function History:get(idx)
  local buf = self._data[(self._read % self._cap) + idx + 1]
  if buf then
    return buffers.get_buffer(buf)
  end
end

---Get a Buffer object representing the last-accessed buffer (before the current one)
---@return Buffer|nil
function History:last()
  local buf = self._data[self._write == 1 and self._len or (self._write - 1)]
  if buf then
    return buffers.get_buffer(buf)
  end
end

---Returns true if the history is empty
---@return boolean
function History:is_empty()
  return self._read == self._write
end

---Returns the maximum number of buffers that can be stored in the history
---@return integer
function History:capacity()
  return self._cap
end

---Returns true if the history contains the given buffer
---@param bufnr bufnr
---@return boolean
function History:contains(bufnr)
  return vim.tbl_contains(self._data, bufnr)
end

---Returns the number of buffers in the history
---@return integer
function History:len()
  return self._len
end

return History
