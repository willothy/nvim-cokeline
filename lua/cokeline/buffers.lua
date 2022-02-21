local has_devicons, rq_devicons = pcall(require, "nvim-web-devicons")

local tbl_concat = table.concat
local tbl_sort = table.sort

local vim_bo = vim.bo
local vim_cmd = vim.cmd
local vim_diagnostics = vim.diagnostic or vim.lsp.diagnostic
local vim_filter = vim.tbl_filter
local vim_fn = vim.fn
local vim_map = vim.tbl_map
local vim_split = vim.split

local gl_settings, buffer_sorter

---@type table<bufnr, valid_index>
local order = {}

---@type bufnr
local current_valid_index

local valid_pick_letters =
  "asdfjkl;ghnmxcvbziowerutyqpASDFJKLGHNMXCVBZIOWERUTYQP"

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

---@param buffers  Buffer[]
---@return Buffer[]
local compute_unique_prefixes = function(buffers)
  local is_windows = not vim_fn.has("win32") == 0

  -- FIXME: it appears in windows sometimes directories are separated by '/'
  -- instead of '\\'??
  if is_windows then
    buffers = vim_map(function(buffer)
      buffer.path = buffer.path:gsub("/", "\\")
      return buffer
    end, buffers)
  end

  local path_separator = not is_windows and "/" or "\\"

  local paths = vim_map(function(buffer)
    return vim_fn.reverse(vim_split(buffer.path, path_separator))
  end, buffers)

  local prefixes = vim_map(function()
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
    buffer.unique_prefix = tbl_concat({
      #prefixes[i] == #paths[i] and path_separator or "",
      vim_fn.join(vim_fn.reverse(prefixes[i]), path_separator),
      #prefixes[i] > 0 and path_separator or "",
    })
  end

  return buffers
end

---@param filename  string
---@param bufnr  bufnr
---@return string
local get_pick_letter = function(filename, bufnr)
  -- If the bufnr has already a letter associated to it return that.
  if taken_pick_letters[bufnr] then
    return taken_pick_letters[bufnr]
  end

  -- If the initial letter of the filename is valid and it hasn't already been
  -- assigned return that.
  local init_letter = filename:sub(1, 1)
  if valid_pick_letters:find(init_letter, nil, true) then
    valid_pick_letters = valid_pick_letters:gsub(init_letter, "")
    taken_pick_letters[bufnr] = init_letter
    return init_letter
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
  local extn = vim_fn.fnamemodify(path, ":e")
  local icon, color = rq_devicons.get_icon_color(
    name,
    extn,
    { default = true }
  )
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

  for _, diagnostic in ipairs(vim_diagnostics.get(bufnr)) do
    if diagnostic.severity == 1 then
      diagnostics.errors = diagnostics.errors + 1
    elseif diagnostic.severity == 2 then
      diagnostics.warnings = diagnostics.warnings + 1
    elseif diagnostic.severity == 3 then
      diagnostics.infos = diagnostics.infos + 1
    elseif diagnostic.severity == 4 then
      diagnostics.hints = diagnostics.hints + 1
    end
  end

  return diagnostics
end

---@param b  table
---@return Buffer
local new_buffer = function(b)
  local opts = vim_bo[b.bufnr]

  local _valid_index = order[b.bufnr] or -1
  local index = -1
  local number = b.bufnr
  local type = opts.buftype
  local is_focused = (number == vim_fn.bufnr("%"))
  local is_modified = opts.modified
  local is_readonly = opts.readonly
  local path = b.name
  local unique_prefix = ""

  local filename = (type == "quickfix" and "quickfix")
    or (#path > 0 and vim_fn.fnamemodify(path, ":t"))
    or "[No Name]"

  local filetype = not (b.variables and b.variables.netrw_browser_active)
      and opts.filetype
    or "netrw"

  local pick_letter = filename ~= "[No Name]"
      and get_pick_letter(filename, number)
    or "?"

  local devicon = has_devicons and get_devicon(path, filename, type)
    or { icon = "", color = "" }

  local diagns = get_diagnostics(number)

  return {
    _valid_index = _valid_index,
    index = index,
    number = number,
    type = type,
    is_focused = is_focused,
    is_modified = is_modified,
    is_readonly = is_readonly,
    path = path,
    unique_prefix = unique_prefix,
    filename = filename,
    filetype = filetype,
    pick_letter = pick_letter,
    devicon = devicon,
    diagnostics = diagns,
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

  vim_cmd("redrawtabline")
end

---@return Buffer[]
local get_valid_buffers = function()
  local buffers = vim_filter(
    function(buffer)
      return buffer.filetype ~= "netrw"
    end,
    vim_map(function(b)
      return new_buffer(b)
    end, vim_fn.getbufinfo({ buflisted = 1 }))
  )

  local valid_buffers = compute_unique_prefixes(
    gl_settings.filter_valid and vim_filter(gl_settings.filter_valid, buffers)
      or buffers
  )

  tbl_sort(valid_buffers, buffer_sorter)

  order = {}
  for i, buffer in ipairs(valid_buffers) do
    buffer._valid_index = i
    order[buffer.number] = buffer._valid_index
    if buffer.is_focused then
      current_valid_index = i
    end
  end

  return valid_buffers
end

---@return Buffer[]
local get_visible_buffers = function()
  _G.cokeline.valid_buffers = get_valid_buffers()

  _G.cokeline.visible_buffers = gl_settings.filter_visible
      and vim_filter(
        gl_settings.filter_visible,
        _G.cokeline.valid_buffers
      )
    or _G.cokeline.valid_buffers

  for i, buffer in ipairs(_G.cokeline.visible_buffers) do
    buffer.index = i
  end

  return _G.cokeline.visible_buffers
end

---@param settings  table
local setup = function(settings)
  gl_settings = settings
  buffer_sorter = (
      settings.new_buffers_position == "last" and sort_by_new_after_last
    )
    or (settings.new_buffers_position == "next" and sort_by_new_after_current)
end

return {
  move_buffer = move_buffer,
  get_valid_buffers = get_valid_buffers,
  get_visible_buffers = get_visible_buffers,
  setup = setup,
}
