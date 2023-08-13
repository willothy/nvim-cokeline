local utils = require("cokeline.utils")
local buffers = require("cokeline.buffers")
local tabs = require("cokeline.tabs")

---@alias ClickHandler<Cx> fun(button_id: number, clicks: number, button: string, modifiers: string, cx: Cx): void
---@alias MouseEnterHandler fun(cx: Cx)
---@alias MouseLeaveHandler fun(cx: Cx)
---@alias Handler<Cx> ClickHandler<Cx> | MouseEnterHandler<Cx> | MouseLeaveHandler<Cx>
---@alias WrappedHandler<Cx> fun(cx: Cx): Handler<Cx>

---@generic Cx
---@class Handlers Singleton event handler manager
---@field click (fun(cx: Cx): Handler<Cx>)[]
---@field private private table<string, WrappedHandler<Cx>[]>
local Handlers = {
  click = {},
  private = {
    click = {},
  },
}

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
  rawset(Handlers.private.click, idx, function(buffer)
    return function(minwid, clicks, button, modifiers)
      return handler(minwid, clicks, button, modifiers, buffer)
    end
  end)
end

---Unregister a click handler
---@param idx number
function Handlers.click:unregister(idx)
  unregister("click", idx)
end

---Default click handler
---@param bufnr bufnr
local function default_click(cx, kind)
  return function(_, _, button)
    if button == "l" then
      if kind == "tab" or kind == "buffer" then
        cx:focus()
      end
    elseif
      kind == "buffer"
      and button == "r"
      and _G.cokeline.config.buffers.delete_on_right_click
    then
      utils.buf_delete(cx.number, _G.cokeline.config.buffers.focus_on_delete)
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
      local kind, id, number = string.match(key, "click_(%a+)_(%d+)_(%d+)")
      if number == nil then
        return
      end
      local cx
      if kind == "tab" then
        cx = tabs.get_tabpage(tonumber(number))
      else
        cx = buffers.get_buffer(tonumber(number))
      end

      if id ~= nil then
        local handler = Handlers.private["click"][tonumber(id)]
        return handler and handler(cx) or default_click(cx, kind)
      else
        return default_click(cx, kind)
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
