local lazy = require("cokeline.lazy")
local state = lazy("cokeline.state")
local buffers = lazy("cokeline.buffers")
local tabs = lazy("cokeline.tabs")
local config = lazy("cokeline.config")

local cmd = vim.cmd
local filter = vim.tbl_filter
local fn = vim.fn
local opt = vim.opt

local toggle = function()
  local listed_buffers = fn.getbufinfo({ buflisted = 1 })
  opt.showtabline = #listed_buffers > 0 and 2 or 0
end

local bufnr_to_close

local close_bufnr = function()
  if bufnr_to_close then
    cmd("b" .. bufnr_to_close)
    bufnr_to_close = nil
  end
end

---@param bufnr  number
local remember_bufnr = function(bufnr)
  if #state.valid_buffers == 1 then
    return
  end

  local deleted_buffer = filter(function(buffer)
    return buffer.number == bufnr
  end, state.valid_buffers)[1]

  -- Neogit buffers do some weird stuff like closing themselves on buffer
  -- change and seem to cause problems. We just ignore them.
  -- See https://github.com/noib3/nvim-cokeline/issues/43
  if
    not deleted_buffer or deleted_buffer.filename:find("Neogit", nil, true)
  then
    return
  end

  local target_index

  if config.buffers.focus_on_delete == "prev" then
    target_index = deleted_buffer._valid_index ~= 1
        and deleted_buffer._valid_index - 1
      or 2
  elseif config.buffers.focus_on_delete == "next" then
    target_index = deleted_buffer._valid_index ~= #state.valid_buffers
        and deleted_buffer._valid_index + 1
      or #state.valid_buffers - 1
  end

  bufnr_to_close = state.valid_buffers[target_index].number
end

local setup = function()
  local autocmd, augroup =
    vim.api.nvim_create_autocmd, vim.api.nvim_create_augroup

  autocmd({ "VimEnter", "BufAdd" }, {
    group = augroup("cokeline_toggle", { clear = true }),
    callback = function()
      require("cokeline.augroups").toggle()
    end,
  })
  autocmd({ "BufDelete", "BufWipeout" }, {
    group = augroup("cokeline_release_taken_letter", { clear = true }),
    callback = function(args)
      require("cokeline.buffers").release_taken_letter(args.buf)
    end,
  })
  if config.history.enabled then
    autocmd("BufLeave", {
      group = augroup("cokeline_buf_history", { clear = true }),
      callback = function(args)
        if vim.api.nvim_buf_is_valid(args.buf) then
          require("cokeline.history"):push(args.buf)
        end
      end,
    })
  end
  if config.tabs then
    autocmd({ "TabNew", "TabClosed" }, {
      group = augroup("cokeline_fetch_tabs", { clear = true }),
      callback = function()
        tabs.fetch_tabs()
      end,
    })
    autocmd("WinEnter", {
      group = augroup("cokeline_update_tab_focus", { clear = true }),
      callback = function()
        local win = vim.api.nvim_get_current_win()
        local tab = vim.api.nvim_win_get_tabpage(win)
        if not state.tab_lookup[tab] then
          tabs.fetch_tabs()
          return
        end
        tabs.update_current(tab)
        for _, w in ipairs(state.tab_lookup[tab].windows) do
          if w.number == win then
            state.tab_lookup[tab].focused = w
            break
          end
        end
      end,
    })
    autocmd("BufEnter", {
      group = augroup("cokeline_update_tab_win_buf", { clear = true }),
      callback = function(args)
        local win = vim.api.nvim_get_current_win()
        local tab = vim.api.nvim_win_get_tabpage(win)
        if not state.tab_lookup[tab] then
          tabs.fetch_tabs()
          return
        end
        for _, w in ipairs(state.tab_lookup[tab].windows) do
          if w.number == win then
            w.buffer = buffers.get_buffer(args.buf)
            break
          end
        end
      end,
    })
  end
end

return {
  close_bufnr = close_bufnr,
  remember_bufnr = remember_bufnr,
  setup = setup,
  toggle = toggle,
}
