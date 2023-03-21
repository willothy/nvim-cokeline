local has_devicons, rq_devicons = pcall(require, "nvim-web-devicons")

local concat = table.concat
local sort = table.sort

local bo = vim.bo
local cmd = vim.cmd
local diagnostic = vim.diagnostic or vim.lsp.diagnostic
local filter = vim.tbl_filter
local fn = vim.fn
local map = vim.tbl_map
local split = vim.split

---@type table<bufnr, valid_index>
local order = {}

---@type bufnr
local current_valid_index

local valid_pick_letters = false

local taken_pick_letters = {}

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
---@field path          string
---@field unique_prefix string
---@field filename      string
---@field filetype      string
---@field pick_letter   string
---@field devicon       table<string, string>
---@field diagnostics   table<string, number>
local Buffer = {}
Buffer.__index = Buffer

---@param buffers  Buffer[]
---@return Buffer[]
local compute_unique_prefixes = function(buffers)
  local is_windows = fn.has("win32") == 1

  -- FIXME: it appears in windows sometimes directories are separated by '/'
  -- instead of '\\'??
  if is_windows then
    buffers = map(function(buffer)
      buffer.path = buffer.path:gsub("/", "\\")
      return buffer
    end, buffers)
  end

  local path_separator = not is_windows and "/" or "\\"

  local paths = map(function(buffer)
    return fn.reverse(split(buffer.path, path_separator))
  end, buffers)

  local prefixes = map(function()
    return {}
  end, buffers)

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

  for i, buffer in ipairs(buffers) do
    buffer.unique_prefix = concat({
      #prefixes[i] == #paths[i] and path_separator or "",
      fn.join(fn.reverse(prefixes[i]), path_separator),
      #prefixes[i] > 0 and path_separator or "",
    })
  end

  return buffers
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
  if _G.cokeline.config.pick.use_filename then
    local init_letter = filename:sub(1, 1)
    if valid_pick_letters:find(init_letter, nil, true) then
      valid_pick_letters = valid_pick_letters:gsub(init_letter, "")
      taken_pick_letters[bufnr] = init_letter
      return init_letter
    end
  end

  -- Return the first valid letter if there is one.
  if #valid_pick_letters > 0 then
    local first_valid = valid_pick_letters:sub(1, 1)
    valid_pick_letters = valid_pick_letters:sub(2)
    taken_pick_letters[bufnr] = first_valid
    return first_valid
  end

  -- Finally, just return a '?' (this is rarely reached, you'd need to have
  -- opened 54 buffers in the same session).
  return "?"
end

---@param path  string
---@param filename  string
---@param type  string
---@return table<string, string>
local get_devicon = function(path, filename, type)
  local name = (type == "terminal") and "terminal" or filename
  local extn = fn.fnamemodify(path, ":e")
  local icon, color =
    rq_devicons.get_icon_color(name, extn, { default = true })
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
  local type = opts.buftype
  local path = b.name

  local filename = (type == "quickfix" and "quickfix")
    or (#path > 0 and fn.fnamemodify(path, ":t"))
    or "[No Name]"

  local filetype = not (b.variables and b.variables.netrw_browser_active)
      and opts.filetype
    or "netrw"

  local pick_letter = filename ~= "[No Name]"
      and get_pick_letter(filename, number)
    or "?"

  local devicon = has_devicons and get_devicon(path, filename, type)
    or { icon = "", color = "" }

  return {
    _valid_index = order[b.bufnr] or -1,
    index = -1,
    number = b.bufnr,
    type = opts.buftype,
    is_focused = (b.bufnr == fn.bufnr("%")),
    is_first = false,
    is_last = false,
    is_modified = opts.modified,
    is_readonly = opts.readonly,
    path = b.name,
    unique_prefix = "",
    filename = filename,
    filetype = filetype,
    pick_letter = pick_letter,
    devicon = devicon,
    diagnostics = get_diagnostics(number),
  }
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

---@param buffer  Buffer
---@param target_valid_index  valid_index
local move_buffer = function(buffer, target_valid_index)
  if buffer._valid_index == target_valid_index then
    return
  end

  order[buffer.number] = target_valid_index

  if buffer._valid_index < target_valid_index then
    for index = (buffer._valid_index + 1), target_valid_index do
      order[_G.cokeline.valid_buffers[index].number] = index - 1
    end
  else
    for index = target_valid_index, (buffer._valid_index - 1) do
      order[_G.cokeline.valid_buffers[index].number] = index + 1
    end
  end

  cmd("redrawtabline")
end

---@return Buffer[]
local get_valid_buffers = function()
  local buffers = map(function(b)
    return Buffer.new(b)
  end, fn.getbufinfo({ buflisted = 1 }))

  buffers = filter(function(buffer)
    return buffer.filetype ~= "netrw"
  end, buffers)

  if _G.cokeline.config.buffers.filter_valid then
    buffers = filter(_G.cokeline.config.buffers.filter_valid, buffers)
  end

  buffers = compute_unique_prefixes(buffers)

  if _G.cokeline.config.buffers.new_buffers_position == "last" then
    sort(buffers, sort_by_new_after_last)
  elseif _G.cokeline.config.buffers.new_buffers_position == "next" then
    sort(buffers, sort_by_new_after_current)
  end

  order = {}
  for i, buffer in ipairs(buffers) do
    buffer._valid_index = i
    order[buffer.number] = buffer._valid_index
    if buffer.is_focused then
      current_valid_index = i
    end
  end

  return buffers
end

---@return Buffer[]
local get_visible_buffers = function()
  _G.cokeline.valid_buffers = get_valid_buffers()

  _G.cokeline.visible_buffers = not _G.cokeline.config.buffers.filter_visible
      and _G.cokeline.valid_buffers
    or filter(
      _G.cokeline.config.buffers.filter_visible,
      _G.cokeline.valid_buffers
    )

  if #_G.cokeline.visible_buffers > 0 then
    _G.cokeline.visible_buffers[1].is_first = true
    _G.cokeline.visible_buffers[#_G.cokeline.visible_buffers].is_last = true
  end

  for i, buffer in ipairs(_G.cokeline.visible_buffers) do
    buffer.index = i
  end

  return _G.cokeline.visible_buffers
end

return {
  Buffer = Buffer,
  get_visible = get_visible_buffers,
  move_buffer = move_buffer,
}
