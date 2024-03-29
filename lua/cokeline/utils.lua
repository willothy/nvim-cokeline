---@param bufnr number
---@param focus_next boolean
---@param wipeout boolean
---@param force boolean
local function buf_del_impl(bufnr, focus_next, wipeout, force)
  local win = vim.fn.bufwinid(bufnr)

  if win ~= -1 then
    -- Get a list of buffers that are valid switch targets
    local switchable = vim.tbl_filter(function(buf)
      return vim.api.nvim_buf_is_valid(buf)
        and vim.bo[buf].buflisted
        and buf ~= bufnr
    end, vim.api.nvim_list_bufs())

    local switch_target
    if #switchable > 0 then
      for _, switch_nr in ipairs(switchable) do
        -- If we're looking for a buffer after the current one, break here
        if switch_nr < bufnr then
          -- Keep looping to find the previous buffer
          -- This also serves as a fallback if there's no
          -- next buffer, and `focus_next` is true
          switch_target = switch_nr
        end
        if switch_nr > bufnr and (focus_next or switch_target == nil) then
          -- We found the next buffer, break
          switch_target = switch_nr
          break
        end
      end
    else
      -- If there's no possible switch target, create a new buffer and switch to it
      switch_target = vim.api.nvim_create_buf(false, true)
      if switch_target == 0 then
        vim.api.nvim_err_writeln("Failed to create new buffer")
      end
    end

    vim.api.nvim_win_set_buf(win, switch_target)
  end

  if vim.api.nvim_buf_is_valid(bufnr) then
    if wipeout then
      vim.cmd.bwipeout({ count = bufnr })
    else
      vim.api.nvim_buf_delete(bufnr, { force = force })
    end
  end
end

---@param bufnr bufnr The buffer to delete
---@param focus "prev" | "next" | nil Buffer to focus on deletion (default: "next")
---@param wipeout boolean Whether to wipe the buffer (default: false)
---Deletes a buffer but keeps window layout
local function buf_delete(bufnr, focus, wipeout)
  bufnr = bufnr or 0
  wipeout = wipeout or false
  local focus_next = true

  if focus == "prev" then
    focus_next = false
  end

  if vim.bo[bufnr].modified then
    vim.ui.select({
      "Save and close",
      "Discard changes and close",
      "Cancel",
    }, {
      prompt = string.format(
        "Buffer %s has unsaved changes.",
        vim.fn.fnamemodify(vim.fn.bufname(bufnr), ":f")
      ),
    }, function(_, choice)
      if choice == 1 then
        if vim.api.nvim_buf_get_name(bufnr) == "" then
          vim.ui.input({
            prompt = "File name: ",
            completion = "file",
          }, function(name)
            if name and name ~= "" then
              vim.api.nvim_buf_set_name(bufnr, name)
              vim.api.nvim_buf_call(bufnr, vim.cmd.write)
              buf_del_impl(bufnr, focus_next, wipeout, false)
            end
          end)
        else
          vim.api.nvim_buf_call(bufnr, vim.cmd.write)
          buf_del_impl(bufnr, focus_next, wipeout, false)
        end
      elseif choice == 2 then
        buf_del_impl(bufnr, focus_next, wipeout, true)
      elseif choice == 3 then
        return
      end
    end)
  elseif vim.bo[bufnr].buftype == "terminal" then
    vim.ui.select({
      "Quit",
      "Cancel",
    }, {
      prompt = string.format(
        "Buffer %s is a terminal, and is still running.",
        vim.fn.fnamemodify(vim.fn.bufname(bufnr), ":t")
      ),
    }, function(_, choice)
      if choice == 1 then
        buf_del_impl(bufnr, focus_next, wipeout, true)
      elseif choice == 2 then
        return
      end
    end)
  else
    buf_del_impl(bufnr, focus_next, wipeout, false)
  end
end

return {
  buf_delete = buf_delete,
}
