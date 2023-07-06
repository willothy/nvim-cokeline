local M = {}

local version = vim.version()

local buffers = require("cokeline.buffers")
local tabs = require("cokeline.tabs")
local rendering = require("cokeline.rendering")
local iter = require("plenary.iterators").iter
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
  for _, component in ipairs(cx.sidebar_left) do
    current_width = current_width + component.width
    if current_width >= col then
      return component, cx.sidebar_left
    end
  end
  if
    _G.cokeline.config.tabs and _G.cokeline.config.tabs.placement == "left"
  then
    for _, component in ipairs(cx.tabs) do
      current_width = current_width + component.width
      if current_width >= col then
        return component, cx.tabs
      end
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
  if
    _G.cokeline.config.tabs and _G.cokeline.config.tabs.placement == "right"
  then
    for _, component in ipairs(cx.tabs) do
      current_width = current_width + component.width
      if current_width >= col then
        return component, cx.tabs
      end
    end
  end
  for _, component in ipairs(cx.sidebar_right) do
    current_width = current_width + component.width
    if current_width >= col then
      return component, cx.sidebar_right
    end
  end
end

local function mouse_leave(hovered)
  local cx
  if hovered.kind == "buffer" then
    cx = buffers.get_buffer(hovered.bufnr)
  elseif hovered.kind == "tab" then
    cx = tabs.get_tabpage(hovered.bufnr)
  elseif hovered.kind == "sidebar" then
    cx = { number = hovered.bufnr, side = hovered.sidebar }
  else
    cx = {}
  end
  if cx then
    cx.is_hovered = false
  end
  if hovered.on_mouse_leave then
    if (hovered.kind ~= "buffer" and hovered.kind ~= "tab") or cx ~= nil then
      hovered.on_mouse_leave(cx)
    end
  end
  M.clear_hovered()
end

local function mouse_enter(component, current)
  local cx
  if component.kind == "buffer" then
    cx = buffers.get_buffer(component.bufnr)
  elseif component.kind == "tab" then
    cx = tabs.get_tabpage(component.bufnr)
  elseif component.kind == "sidebar" then
    cx = { number = component.bufnr, side = component.sidebar }
  else
    cx = {}
  end
  if cx then
    cx.is_hovered = true
  end
  if component.on_mouse_enter then
    if
      (component.kind ~= "buffer" and component.kind ~= "tab") or cx ~= nil
    then
      component.on_mouse_enter(cx, current.screencol)
    end
  end
  M.set_hovered({
    index = component.index,
    bufnr = cx and cx.number,
    on_mouse_leave = component.on_mouse_leave,
    kind = component.kind,
  })
end

local function on_hover(current)
  M.clear_dragging()
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
      mouse_leave(hovered)
    end
    if not component then
      vim.cmd.redrawtabline()
      return
    end

    mouse_enter(component, current)
    vim.cmd.redrawtabline()
  elseif hovered ~= nil then
    mouse_leave(hovered)
    vim.cmd.redrawtabline()
  end
  last_position = current
end

local function width(bufs, buf)
  return iter(bufs)
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

function M.mouse_pos(drag, key)
  drag = drag or {}
  local ok, pos = pcall(vim.fn.getmousepos)
  if not ok then
    return
  end

  return {
    dragging = type(drag) == "table" and drag[key] or drag,
    screencol = pos.screencol,
    screenrow = pos.screenrow,
    line = pos.line,
    column = pos.column,
    winid = pos.winid,
    winrow = pos.winrow,
    wincol = pos.wincol,
  }
end

function M.setup()
  if
    _G.cokeline.config.mappings.disable_mouse == true or version.minor < 8
  then
    return
  end

  if version.minor >= 9 and vim.on_key and vim.keycode then
    local mouse_move = vim.keycode("<MouseMove>")
    local drag = {
      [vim.keycode("<LeftDrag>")] = "l",
      [vim.keycode("<RightDrag>")] = "r",
      [vim.keycode("<MiddleDrag>")] = "m",
    }
    vim.on_key(function(k)
      local data = M.mouse_pos(drag, k)
      if data then
        vim.schedule_wrap(function(key)
          if key == mouse_move then
            on_hover(data)
          elseif drag[key] then
            on_drag(data)
          end
        end)(k)
      end
    end)
  elseif vim.o.mousemoveevent then
    vim.keymap.set({ "n", "" }, "<MouseMove>", function()
      local data = M.mouse_pos()
      if data then
        on_hover(data)
      end
    end)
    vim.keymap.set({ "n", "" }, "<LeftDrag>", function()
      local data = M.mouse_pos("l")
      if data then
        on_drag(data)
      end
    end)
  end
end

return M
