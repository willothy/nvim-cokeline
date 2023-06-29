local M = {}

local version = vim.version()

local buffers = require("cokeline.buffers")
local rendering = require("cokeline.rendering")
local last_position = nil

function M.hovered()
  return _G.cokeline.__hovered
end

function M.set_hovered(val)
  _G.cokeline.__hovered = val
end

function M.clear_hovered()
  _G.cokeline.__hovered = nil
end

function M.dragging()
  return _G.cokeline.__dragging
end

function M.set_dragging(val)
  _G.cokeline.__dragging = val
end

function M.clear_dragging()
  _G.cokeline.__dragging = nil
end

function M.get_current(col)
  local bufs = buffers.get_visible()
  if not bufs then
    return
  end
  local cx = rendering.prepare(bufs)

  local current_width = 0
  for _, component in ipairs(cx.sidebar) do
    current_width = current_width + component.width
    if current_width >= col then
      return component, cx.sidebar
    end
  end
  for _, component in ipairs(cx.buffers) do
    current_width = current_width + component.width
    if current_width >= col then
      return component, cx.buffers
    end
  end
  current_width = current_width + cx.gap
  if current_width >= col then
    return
  end
  for _, component in ipairs(cx.rhs) do
    current_width = current_width + component.width
    if current_width >= col then
      return component, cx.rhs
    end
  end
end

local function on_hover(current)
  local hovered = M.hovered()
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

    if
      component
      and hovered
      and component.index == hovered.index
      and component.bufnr == hovered.bufnr
    then
      return
    end

    if hovered ~= nil then
      local buf = buffers.get_buffer(hovered.bufnr)
      if buf then
        buf.is_hovered = false
      end
      if hovered.on_mouse_leave then
        if hovered.kind == "buffer" then
          if buf ~= nil then
            hovered.on_mouse_leave(buf)
          end
        else
          hovered.on_mouse_leave(buf)
        end
      end
      M.clear_hovered()
    end
    if not component then
      vim.cmd.redrawtabline()
      return
    end

    local buf = buffers.get_buffer(component.bufnr)
    if buf then
      buf.is_hovered = true
    end
    if component.on_mouse_enter then
      if component.kind == "buffer" then
        if buf ~= nil then
          component.on_mouse_enter(buf, current.screencol)
        end
      else
        component.on_mouse_enter(buf, current.screencol)
      end
    end
    M.set_hovered({
      index = component.index,
      bufnr = buf and buf.number or nil,
      on_mouse_leave = component.on_mouse_leave,
      kind = component.kind,
    })
    vim.cmd.redrawtabline()
  elseif hovered ~= nil then
    local buf = buffers.get_buffer(hovered.bufnr)
    if buf then
      buf.is_hovered = false
    end
    if hovered.on_mouse_leave then
      if hovered.kind == "buffer" then
        if buf ~= nil then
          hovered.on_mouse_leave(buf)
        end
      else
        hovered.on_mouse_leave(buf)
      end
    end
    M.clear_hovered()
    vim.cmd.redrawtabline()
  end
  last_position = current
end

local function width(bufs, buf)
  return vim
    .iter(bufs)
    :filter(function(v)
      return v.bufnr == buf
    end)
    :map(function(v)
      return v.width
    end)
    :fold(0, function(acc, v)
      return acc + v
    end)
end

local function start_pos(bufs, buf)
  local pos = 0
  for _, v in ipairs(bufs) do
    if v.bufnr == buf then
      return pos
    end
    pos = pos + v.width
  end
  return pos
end

local function on_drag(pos)
  if pos.dragging == "l" then
    local current, bufs = M.get_current(pos.screencol)
    if current == nil or bufs == nil or current.kind ~= "buffer" then
      return
    end

    -- if we're not dragging yet or we're dragging the same buffer, start dragging
    if M.dragging() == current.bufnr or not M.dragging() then
      M.set_dragging(current.bufnr)
      return
    end

    -- dragged buffer
    local dragged_buf = buffers.get_buffer(M.dragging())
    if not dragged_buf then
      return
    end

    -- current (hovered) buffer
    local cur_buf = buffers.get_buffer(current.bufnr)
    if not cur_buf then
      return
    end

    -- start position of dragged buffer
    local dragging_start = start_pos(bufs, M.dragging())
    -- width of the current (hovered) buffer
    local cur_buf_width = width(bufs, current.bufnr)

    if
      -- buffer is being dragged to the left
      (
        dragging_start > pos.screencol
        and pos.screencol + cur_buf_width > dragging_start
      )
      -- buffer is being dragged to the right
      or dragging_start + cur_buf_width <= pos.screencol
    then
      buffers.move_buffer(dragged_buf, cur_buf._valid_index)
    end
  end
end

function M.setup()
  if version.minor < 8 or not vim.on_key then
    return
  end

  local mouse_move = vim.keycode("<MouseMove>")
  local drag = {
    [vim.keycode("<LeftDrag>")] = "l",
    [vim.keycode("<RightDrag>")] = "r",
    [vim.keycode("<MiddleDrag>")] = "m",
  }
  vim.on_key(function(key)
    local ok, pos = pcall(vim.fn.getmousepos)
    if not ok then
      return
    end

    local data = {
      dragging = drag[key],
      screencol = pos.screencol,
      screenrow = pos.screenrow,
      line = pos.line,
      column = pos.column,
      winid = pos.winid,
      winrow = pos.winrow,
      wincol = pos.wincol,
    }
    if key == mouse_move then
      M.clear_dragging()
      on_hover(data)
    elseif drag[key] then
      local hov = M.hovered()
      if hov then
        local buf = buffers.get_buffer(hov.bufnr)
        if buf then
          buf.is_hovered = false
        end
        if hov.kind == "buffer" then
          if buf and hov.on_mouse_leave then
            hov.on_mouse_leave(buf)
          end
        elseif hov.on_mouse_leave then
          hov.on_mouse_leave()
        end
        M.clear_hovered()
      end
      on_drag(data)
    end
  end)
end

return M
