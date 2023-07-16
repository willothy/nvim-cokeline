local has_devicons, rq_devicons = pcall(require, "nvim-web-devicons")

local concat = table.concat
local sort = table.sort

local bo = vim.bo
local cmd = vim.cmd
local diagnostic = vim.diagnostic or vim.lsp.diagnostic
local fn = vim.fn
local split = vim.split

local util = require("cokeline.utils")
local iter = require("plenary.iterators").iter

---@type bufnr
local current_valid_index

local valid_pick_letters = false

local first_valid = 1

local taken_pick_letters = {}
local taken_pick_indices = {}

local M = {}

---@diagnostic disable: duplicate-doc-class

---@alias valid_index  number
---@alias index  number
---@alias bufnr  number

---@class Buffer
---@field _valid_index  valid_index
---@field index         index
---@field number        bufnr
---@field type          string
---@field is_focused    boolean
---@field is_modified   boolean
---@field is_readonly   boolean
---@field is_hovered    boolean Whether the current component is hovered
---@field buf_hovered   boolean Whether any component in the buffer is hovered
---@field path          string
---@field unique_prefix string
---@field filename      string
---@field filetype      string
---@field pick_letter   string
---@field devicon       table<string, string>
---@field diagnostics   table<string, number>
local Buffer = {}
Buffer.__index = Buffer

---@param buffers  Iter<Buffer>
---@return Iter<Buffer>
local compute_unique_prefixes = function(buffers)
  local is_windows = fn.has("win32") == 1

  local path_separator = not is_windows and "/" or "\\"

  local prefixes = {}
  local paths = {}
  buffers = buffers
    :map(function(buffer)
      prefixes[#prefixes + 1] = {}
      paths[#paths + 1] = fn.reverse(
        split(
          is_windows and buffer.path:gsub("/", "\\") or buffer.path,
          path_separator
        )
      )
      return buffer
    end)
    :tolist()

  for i = 1, #paths do
    for j = i + 1, #paths do
      local k = 1
      while paths[i][k] == paths[j][k] and paths[i][k] do
        k = k + 1
        prefixes[i][k - 1] = prefixes[i][k - 1] or paths[i][k]
        prefixes[j][k - 1] = prefixes[j][k - 1] or paths[j][k]
      end
      if k ~= 1 then
        prefixes[i][k - 1] = prefixes[i][k - 1] or paths[i][k]
        prefixes[j][k - 1] = prefixes[j][k - 1] or paths[j][k]
      end
    end
  end

  return iter(buffers):enumerate():map(function(i, buffer)
    buffer.unique_prefix = concat({
      #prefixes[i] == #paths[i] and path_separator or "",
      fn.join(fn.reverse(prefixes[i]), path_separator),
      #prefixes[i] > 0 and path_separator or "",
    })
    return i, buffer
  end)
end

---@param filename  string
---@param bufnr  bufnr
---@return string
local get_pick_letter = function(filename, bufnr)
  -- Initialize the valid letters string, if not already initialized
  if not valid_pick_letters then
    valid_pick_letters = _G.cokeline.config.pick.letters
  end

  -- If the bufnr has already a letter associated to it return that.
  if taken_pick_letters[bufnr] then
    return taken_pick_letters[bufnr]
  end

  -- If the config option pick.use_filename is true, and the initial letter
  -- of the filename is valid and it hasn't already been assigned return that.
  if _G.cokeline.config.pick.use_filename and filename ~= "" then
    local init_letter = vim.fn.strcharpart(filename, 0, 1)
    local idx = valid_pick_letters:find(init_letter, nil, true)

    if idx == nil or taken_pick_indices[idx] then
      while
        taken_pick_indices[first_valid]
        and first_valid <= vim.fn.strcharlen(valid_pick_letters)
      do
        first_valid = first_valid + 1
      end
      idx = first_valid
    end
    if idx then
      local letter = vim.fn.strcharpart(valid_pick_letters, idx - 1, 1)
      if letter and letter ~= "" then
        taken_pick_letters[bufnr] = letter
        taken_pick_indices[idx] = true

        return letter
      end
    end
  end

  -- Return the first valid letter if there is one.
  while
    taken_pick_indices[first_valid]
    and first_valid <= vim.fn.strcharlen(valid_pick_letters)
  do
    first_valid = first_valid + 1
  end
  if first_valid <= vim.fn.strcharlen(valid_pick_letters) then
    local letter = vim.fn.strcharpart(valid_pick_letters, first_valid - 1, 1)
    taken_pick_letters[bufnr] = letter
    taken_pick_indices[first_valid] = true
    first_valid = first_valid + 1
    return letter
  end

  -- Finally, just return a '?' (this is rarely reached, you'd need to have
  -- opened 54 buffers in the same session).
  return "?"
end

---@param path  string
---@param filename  string
---@param buftype  string
---@param filetype  string
---@return table<string, string>
local get_devicon = function(path, filename, buftype, filetype)
  local name = (buftype == "terminal") and "terminal" or filename

  local extn = fn.fnamemodify(path, ":e")
  local icon, color =
    rq_devicons.get_icon_color(name, extn, { default = false })
  if not icon then
    icon, color =
      rq_devicons.get_icon_color_by_filetype(filetype, { default = true })
  end

  return {
    icon = icon .. " ",
    color = color,
  }
end

---@param bufnr  bufnr
---@return table<string, number>
local get_diagnostics = function(bufnr)
  local diagnostics = {
    errors = 0,
    warnings = 0,
    infos = 0,
    hints = 0,
  }

  for _, d in ipairs(diagnostic.get(bufnr)) do
    if d.severity == 1 then
      diagnostics.errors = diagnostics.errors + 1
    elseif d.severity == 2 then
      diagnostics.warnings = diagnostics.warnings + 1
    elseif d.severity == 3 then
      diagnostics.infos = diagnostics.infos + 1
    elseif d.severity == 4 then
      diagnostics.hints = diagnostics.hints + 1
    end
  end

  return diagnostics
end

---@param b  table
---@return Buffer
Buffer.new = function(b)
  local opts = bo[b.bufnr]

  local number = b.bufnr
  local buftype = opts.buftype
  local path = b.name

  local filename = (type == "quickfix" and "quickfix")
    or (#path > 0 and fn.fnamemodify(path, ":t"))

  local filetype = not (b.variables and b.variables.netrw_browser_active)
      and opts.filetype
    or "netrw"

  local pick_letter = get_pick_letter(filename or "", number)

  local devicon = has_devicons
      and get_devicon(path, filename, buftype, filetype)
    or { icon = "", color = "" }

  return setmetatable({
    _valid_index = _G.cokeline.buf_order[b.bufnr] or -1,
    index = -1,
    number = b.bufnr,
    type = opts.buftype,
    is_focused = (b.bufnr == fn.bufnr("%")),
    is_first = false,
    is_last = false,
    is_modified = opts.modified,
    is_readonly = opts.readonly,
    is_hovered = false,
    buf_hovered = false,
    path = b.name,
    unique_prefix = "",
    filename = filename or "[No Name]",
    filetype = filetype,
    pick_letter = pick_letter,
    devicon = devicon,
    diagnostics = get_diagnostics(number),
  }, Buffer)
end

---@param self Buffer
---Deletes the buffer
function Buffer:delete()
  util.buf_delete(self.number)
  vim.cmd.redrawtabline()
end

---@param self Buffer
---Focuses the buffer
function Buffer:focus()
  vim.api.nvim_set_current_buf(self.number)
end

---@param self Buffer
---@return number
---Returns the number of lines in the buffer
function Buffer:lines()
  return vim.api.nvim_buf_line_count(self.number)
end

---@param self Buffer
---@return string[]
---Returns the buffer's lines
function Buffer:text()
  return vim.api.nvim_buf_get_lines(self.number, 0, -1, false)
end

---@param buf Buffer
---@return boolean
---Returns true if the buffer is valid
function Buffer:is_valid()
  return vim.api.nvim_buf_is_valid(self.number)
end

---@param buffer  Buffer
---@return boolean
local is_old = function(buffer)
  for _, buf in pairs(_G.cokeline.valid_buffers) do
    if buffer.number == buf.number then
      return true
    end
  end
  return false
end

---@param buffer  Buffer
---@return boolean
local is_new = function(buffer)
  return not is_old(buffer)
end

---Sorter used to open new buffers at the end of the bufferline.
---@param buffer1  Buffer
---@param buffer2  Buffer
---@return boolean
local sort_by_new_after_last = function(buffer1, buffer2)
  if is_old(buffer1) and is_old(buffer2) then
    return buffer1._valid_index < buffer2._valid_index
  elseif is_old(buffer1) and is_new(buffer2) then
    return true
  elseif is_new(buffer1) and is_old(buffer2) then
    return false
  else
    return buffer1.number < buffer2.number
  end
end

---Sorter used to open new buffers next to the current buffer.
---@param buffer1  Buffer
---@param buffer2  Buffer
---@return boolean
local sort_by_new_after_current = function(buffer1, buffer2)
  if is_old(buffer1) and is_old(buffer2) then
    -- If both buffers are either before or after (inclusive) the current
    -- buffer, respect the current order.
    if
      (buffer1._valid_index - current_valid_index)
        * (buffer2._valid_index - current_valid_index)
      >= 0
    then
      return buffer1._valid_index < buffer2._valid_index
    end
    return buffer1._valid_index < current_valid_index
  elseif is_old(buffer1) and is_new(buffer2) then
    return buffer1._valid_index <= current_valid_index
  elseif is_new(buffer1) and is_old(buffer2) then
    return current_valid_index < buffer2._valid_index
  else
    return buffer1.number < buffer2.number
  end
end

---Sorter used to order buffers by full path.
---@param buffer1  Buffer
---@param buffer2  Buffer
---@return boolean
local sort_by_directory = function(buffer1, buffer2)
  return buffer1.path < buffer2.path
end

---Sorted used to order buffers by number, as in the default tabline.
---@param buffer1  Buffer
---@param buffer2  Buffer
---@return boolean
local sort_by_number = function(buffer1, buffer2)
  return buffer1.number < buffer2.number
end

---@param bufnr  bufnr
---@return nil
function M.release_taken_letter(bufnr)
  if taken_pick_letters[bufnr] then
    local idx = valid_pick_letters:find(taken_pick_letters[bufnr])
    taken_pick_indices[idx] = nil
    taken_pick_letters[bufnr] = nil
  end
end

---@param buffer  Buffer
---@param target_valid_index  valid_index
function M.move_buffer(buffer, target_valid_index)
  if buffer._valid_index == target_valid_index then
    return
  end

  _G.cokeline.buf_order[buffer.number] = target_valid_index

  if buffer._valid_index < target_valid_index then
    for index = (buffer._valid_index + 1), target_valid_index do
      _G.cokeline.buf_order[_G.cokeline.valid_buffers[index].number] = index
        - 1
    end
  else
    for index = target_valid_index, (buffer._valid_index - 1) do
      _G.cokeline.buf_order[_G.cokeline.valid_buffers[index].number] = index
        + 1
    end
  end

  cmd("redrawtabline")
end

---@return Buffer[]
function M.get_valid_buffers()
  if not _G.cokeline.buf_order then
    _G.cokeline.buf_order = {}
  end

  local info = fn.getbufinfo({ buflisted = 1 })
  ---@type Iter<Buffer>
  local buffers = iter(info):map(Buffer.new):filter(function(buffer)
    return buffer.filetype ~= "netrw"
  end)

  if _G.cokeline.config.buffers.filter_valid then
    ---@type Iter<Buffer>
    buffers = buffers:filter(_G.cokeline.config.buffers.filter_valid)
  end

  ---@type Buffer[]
  buffers = compute_unique_prefixes(buffers)

  if current_valid_index == nil then
    _G.cokeline.buf_order = {}
    buffers = buffers
      :map(function(i, buffer)
        buffer._valid_index = i
        _G.cokeline.buf_order[buffer.number] = buffer._valid_index
        if buffer.is_focused then
          current_valid_index = i
        end
        return buffer
      end)
      :tolist()
  else
    buffers = buffers
      :map(function(_, buf)
        return buf
      end)
      :tolist()
  end

  if type(_G.cokeline.config.buffers.new_buffers_position) == "function" then
    sort(buffers, _G.cokeline.config.buffers.new_buffers_position)
  elseif _G.cokeline.config.buffers.new_buffers_position == "last" then
    sort(buffers, sort_by_new_after_last)
  elseif _G.cokeline.config.buffers.new_buffers_position == "next" then
    sort(buffers, sort_by_new_after_current)
  elseif _G.cokeline.config.buffers.new_buffers_position == "directory" then
    sort(buffers, sort_by_directory)
  elseif _G.cokeline.config.buffers.new_buffers_position == "number" then
    sort(buffers, sort_by_number)
  end

  _G.cokeline.buf_order = {}
  for i, buffer in ipairs(buffers) do
    buffer._valid_index = i
    _G.cokeline.buf_order[buffer.number] = buffer._valid_index
    if buffer.is_focused then
      current_valid_index = i
    end
  end

  return buffers
end

---@param unsorted boolean
---@return Buffer[]
function M.get_visible()
  _G.cokeline.valid_buffers = M.get_valid_buffers()
  _G.cokeline.valid_lookup = {}

  local bufs = iter(_G.cokeline.valid_buffers):map(function(buffer)
    _G.cokeline.valid_lookup[buffer.number] = buffer
    return buffer
  end)

  if _G.cokeline.config.buffers.filter_visible then
    bufs = bufs:filter(_G.cokeline.config.buffers.filter_visible)
  end

  bufs = bufs:enumerate():map(function(i, buf)
    buf.index = i
    return buf
  end)

  if not _G.cokeline.config.pick.use_filename then
    bufs = bufs:map(function(buf)
      buf.pick_letter = get_pick_letter(buf.filename, buf.number)
      return buf
    end)
  end

  _G.cokeline.visible_buffers = bufs:tolist()

  if #_G.cokeline.visible_buffers > 0 then
    _G.cokeline.visible_buffers[1].is_first = true
    _G.cokeline.visible_buffers[#_G.cokeline.visible_buffers].is_last = true
  end

  return _G.cokeline.visible_buffers
end

---Get Buffer
---@param bufnr number
---@return Buffer|nil
function M.get_buffer(bufnr)
  return _G.cokeline.valid_lookup[bufnr]
end

---Wrapper around `vim.api.nvim_get_current_buf`, returns Buffer object
---@return Buffer|nil
function M.get_current()
  local bufnr = vim.api.nvim_get_current_buf()
  if bufnr then
    return M.get_buffer(bufnr)
  end
end

---@param bufnr bufnr
---@return boolean
function M.is_visible(bufnr)
  local buf = M.get_buffer(bufnr)
  if not buf then
    return false
  end
  if
    _G.cokeline.config.buf.filter_valid
    and not _G.cokeline.config.buffers.filter_valid(buf)
  then
    return false
  end
  if
    _G.cokeline.config.buffers.filter_visible
    and not _G.cokeline.config.buffers.filter_visible(buf)
  then
    return false
  end
  return true
end

M.Buffer = Buffer

return M
