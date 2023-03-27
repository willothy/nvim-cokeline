local utils = require("cokeline/utils")
local buffers = require("cokeline/buffers")

---@alias ClickHandler fun(button_id: number, clicks: number, button: string, modifiers: string, buffer: Buffer): void
---@alias WrappedClickHandler fun(buffer: Buffer): ClickHandler

---@class Handlers Singleton event handler manager
---@field click WrappedClickHandler[]
---@field private private table<string, WrappedClickHandler[]>
local Handlers = {
  click = {},
  private = {
    click = {},
  },
}

---@param handler ClickHandler
---@param kind string
---@param idx number
local function register(handler, kind, idx)
  -- for global handlers
  if idx == nil then
    idx = kind
    kind = nil
  end
  rawset(Handlers.private[kind], idx, function(buffer)
    return function(minwid, clicks, button, modifiers)
      return handler(minwid, clicks, button, modifiers, buffer)
    end
  end)
end

---@param kind string
---@param idx number
local function unregister(kind, idx)
  if idx == nil then
    idx = kind
    kind = nil
  end
  rawset(Handlers.private[kind], idx, nil)
end

---Register a click handler
---@param idx number
---@param handler ClickHandler
function Handlers.click:register(idx, handler)
  register(handler, "click", idx)
end

---Unregister a click handler
---@param idx number
function Handlers.click:unregister(idx)
  unregister("click", idx)
end

---Default click handler
---@param bufnr bufnr
local function default_click(buffer)
  return function(_, _, button)
    if button == "l" then
      vim.api.nvim_set_current_buf(buffer.number)
    elseif
      button == "r" and _G.cokeline.config.buffers.delete_on_right_click
    then
      utils.buf_delete(
        buffer.number,
        _G.cokeline.config.buffers.focus_on_delete
      )
    end
  end
end

---Default close handler
---@param bufnr bufnr
local function default_close(buffer)
  return function(_, _, button)
    if button == "l" then
      utils.buf_delete(
        buffer.number,
        _G.cokeline.config.buffers.focus_on_delete
      )
    end
  end
end

--- Public handlers interface
return setmetatable({}, {
  __index = function(_, key)
    --- Retrieve a helper for registering events
    local helper = rawget(Handlers, key)
    if helper ~= nil then
      return key ~= "private" and helper or nil
    end

    --- If there's no helper, evaluate the key to get a handler
    local prefix = string.sub(key, 1, 5)
    if prefix == "click" then
      local c_id, bufnr = string.match(key, "click_(%d+)_(%d+)")
      if bufnr == nil then
        return
      end
      local buffer = buffers.get_buffer(tonumber(bufnr))
      if c_id ~= nil then
        local handler = Handlers.private["click"][tonumber(c_id)]
        return handler and handler(buffer) or default_click(buffer)
      else
        return default_click(buffer)
      end
    elseif prefix == "close" then
      local bufnr = string.match(key, "close_(%d+)")
      if bufnr then
        local buffer = buffers.get_buffer(tonumber(bufnr))
        return default_close(buffer)
      end
    end
    return nil
  end,
  __newindex = function()
    vim.api.nvim_err_writeln("Cannot set fields in cokeline.handlers")
    return nil
  end,
})
