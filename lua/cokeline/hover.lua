local M = {}

local version = vim.version()

local buffers = require("cokeline.buffers")
local rendering = require("cokeline.rendering")
local last_position = nil

function M.hovered()
  return _G.cokeline.__hovered
end

function M.get_current(col)
  local bufs = buffers.get_visible(true)
  if not bufs then
    return
  end
  local cx = rendering.prepare(buffers.get_visible())

  local current_width = 0
  for _, component in ipairs(cx.sidebar) do
    current_width = current_width + component.width
    if current_width >= col then
      return component
    end
  end
  for _, component in ipairs(cx.buffers) do
    current_width = current_width + component.width
    if current_width >= col then
      return component
    end
  end
  current_width = current_width + cx.gap
  if current_width >= col then
    return
  end
  for _, component in ipairs(cx.rhs) do
    current_width = current_width + component.width
    if current_width >= col then
      return component
    end
  end
end

local function on_hover(current)
  local hovered = _G.cokeline.__hovered
  if vim.o.showtabline == 0 then
    return
  end
  if current.screenrow == 1 then
    if
      last_position
      and hovered
      and last_position.screencol == current.screencol
    then
      return
    end
    local component = M.get_current(current.screencol)

    if not component then
      if hovered ~= nil then
        local buf = buffers.get_buffer(hovered.bufnr)
        if buf then
          buf.is_hovered = false
          if hovered.on_mouse_leave then
            hovered.on_mouse_leave(buf)
          end
        end
        _G.cokeline.__hovered = nil
      end
      vim.cmd.redrawtabline()
      return
    end

    local buf = buffers.get_buffer(component.bufnr)
    if buf then
      buf.is_hovered = true
      if component.on_mouse_enter then
        component.on_mouse_enter(buf, current.screencol)
      end
    end
    _G.cokeline.__hovered = {
      index = component.index,
      bufnr = buf and buf.number or nil,
      on_mouse_leave = component.on_mouse_leave,
    }
    vim.cmd.redrawtabline()
  elseif hovered ~= nil then
    local buf = buffers.get_buffer(hovered.bufnr)
    if buf then
      buf.is_hovered = false
      if hovered.on_mouse_leave then
        hovered.on_mouse_leave(buf)
      end
    end
    _G.cokeline.__hovered = nil
    vim.cmd.redrawtabline()
  end
  last_position = current
end

function M.setup()
  if version.minor < 8 then
    return
  end

  vim.keymap.set({ "", "i" }, "<MouseMove>", function()
    local ok, pos = pcall(vim.fn.getmousepos)
    if not ok then
      return
    end
    on_hover(pos)
    return "<MouseMove>"
  end, { expr = true })
end

return M
