local M = {}

local version = vim.version()

local buffers = require("cokeline.buffers")
local rendering = require("cokeline.rendering")
local last_position = nil

function M.hovered()
  return _G.cokeline.__hovered
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
      _G.cokeline.__hovered = nil
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
    _G.cokeline.__hovered = {
      index = component.index,
      bufnr = buf and buf.number or nil,
      on_mouse_leave = component.on_mouse_leave,
      kind = component.kind,
    }
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
    _G.cokeline.__hovered = nil
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
    if not current or current.kind ~= "buffer" or not bufs then
      return
    end

    if not _G.cokeline.__dragging then
      local buf = buffers.get_buffer(current.bufnr)
      if not buf then
        return
      end
      _G.cokeline.__dragging = current.bufnr
    end
    if _G.cokeline.__dragging == current.bufnr then
      return
    end
    if _G.cokeline.__dragging then
      local buf = buffers.get_buffer(_G.cokeline.__dragging)
      local dragging_start = start_pos(bufs, _G.cokeline.__dragging)
      local cur_buf_width = width(bufs, current.bufnr)
      if buf then
        if dragging_start > pos.screencol then
          if pos.screencol + cur_buf_width > dragging_start then
            buffers.move_buffer(
              buf,
              buffers.get_buffer(current.bufnr)._valid_index
            )
          end
        else
          if dragging_start + cur_buf_width <= pos.screencol then
            buffers.move_buffer(
              buf,
              buffers.get_buffer(current.bufnr)._valid_index
            )
          end
        end
      end
    end
  end
end

function M.setup()
  if version.minor < 8 then
    return
  end

  vim.api.nvim_create_autocmd("MouseMove", {
    callback = function(ev)
      if ev.data.dragging then
        local hov = M.hovered()
        if hov ~= nil then
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
          _G.cokeline.__hovered = nil
        end
        on_drag(ev.data)
      else
        _G.cokeline.__dragging = nil
        on_hover(ev.data)
      end
      return "<MouseMove>"
    end,
  })

  -- vim.keymap.set({ "", "i" }, "<MouseMove>", function()
  --   local ok, pos = pcall(vim.fn.getmousepos)
  --   if ok then
  --     on_hover(pos)
  --   end
  --   return "<MouseMove>"
  -- end, { expr = true, noremap = true })
  -- vim.keymap.set({ "", "i" }, "<LeftDrag>", function()
  --   local ok, pos = pcall(vim.fn.getmousepos)
  --   if ok then
  --     pos.dragging = "l"
  --     on_drag(pos)
  --   end
  --   return "<MouseMove>"
  -- end, { expr = true, noremap = true })
end

return M
