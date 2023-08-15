local buffers = require("cokeline.buffers")
local Buffer = buffers.Buffer

local M = {}

---@class Window
---@field number window
---@field buffer Buffer
local Window = {}
Window.__index = Window

function Window.new(winnr)
  local bufnr = vim.api.nvim_win_get_buf(winnr)
  local win = {
    number = winnr,
    buffer = buffers.get_buffer(bufnr)
      or Buffer.new({ bufnr = bufnr, name = vim.api.nvim_buf_get_name(bufnr) }),
  }
  return setmetatable(win, Window)
end

function Window:close()
  pcall(vim.api.nvim_win_close, self.number, false)
end

function Window:focus()
  vim.api.nvim_set_current_win(self.number)
end

---@class TabPage
---@field number tabpage
---@field index number
---@field windows Window[]
---@field focused Window
---@field is_first boolean
---@field is_last boolean
---@field is_active boolean
---@field is_hovered boolean  Whether the current component is hovered
---@field tab_hovered boolean Whether the tab is hovered
local TabPage = {}
TabPage.__index = TabPage

function TabPage.new(tabnr, index, is_first, is_last, is_active)
  local active_win = vim.api.nvim_tabpage_get_win(tabnr)
  local windows = vim.api.nvim_tabpage_list_wins(tabnr)

  local focused
  for i, winnr in ipairs(windows) do
    windows[i] = Window.new(winnr)
    if winnr == active_win then
      focused = windows[i]
    end
  end

  local tab = {
    number = tabnr,
    index = index,
    windows = windows,
    focused = focused,
    is_active = is_active,
    is_first = is_first,
    is_last = is_last,
  }
  return setmetatable(tab, TabPage)
end

function TabPage:focus()
  vim.api.nvim_set_current_tabpage(self.number)
end

function TabPage:close()
  for _, win in ipairs(self.windows) do
    win:close()
  end
end

function M.update_current(tabnr)
  for _, t in ipairs(_G.cokeline.tab_cache) do
    if t.number == tabnr then
      t.is_active = true
    else
      t.is_active = false
    end
  end
end

function M.fetch_tabs()
  local tabs = {}
  local tabnrs = vim.api.nvim_list_tabpages()
  local active_tab = vim.api.nvim_get_current_tabpage()
  table.sort(tabnrs, function(a, b)
    return a < b
  end)
  for t, tabnr in ipairs(tabnrs) do
    if _G.cokeline.tab_lookup[tabnr] ~= nil then
      tabs[t] = _G.cokeline.tab_lookup[tabnr]
      tabs[t].is_active = tabnr == active_tab
      tabs[t].is_first = t == 1
      tabs[t].is_last = t == #tabnrs
      tabs[t].index = t
      local windows = vim.api.nvim_tabpage_list_wins(tabnr)
      for i, winnr in ipairs(windows) do
        if
          tabs[t].windows[i] == nil
          or tabs[t].windows[i].buffer == nil
          or tabs[t].windows[i].buffer.number
            ~= vim.api.nvim_win_get_buf(winnr)
        then
          tabs[t].windows[i] = Window.new(winnr)
        end
      end
    else
      tabs[t] =
        TabPage.new(tabnr, t, t == 1, t == #tabnrs, tabnr == active_tab)
      _G.cokeline.tab_lookup[tabnr] = tabs[t]
    end
  end
  _G.cokeline.tab_cache = tabs
end

function M.get_tabs()
  if not _G.cokeline.tab_cache or #_G.cokeline.tab_cache == 0 then
    M.fetch_tabs()
  end
  return _G.cokeline.tab_cache
end

function M.get_tabpage(tabnr)
  return _G.cokeline.tab_lookup[tabnr]
end

return M
