local has_devicons, rq_devicons = pcall(require, 'nvim-web-devicons')
local rq_mappings = require('cokeline/mappings')

local tbl_concat = table.concat
local tbl_sort = table.sort

local vim_bo = vim.bo
local vim_cmd = vim.cmd
local vim_contains = vim.tbl_contains
local vim_diagnostics = vim.diagnostic or vim.lsp.diagnostic
local vim_filter = vim.tbl_filter
local vim_fn = vim.fn
local vim_map = vim.tbl_map
local vim_split = vim.split

local gl_settings, gl_buffer_sorter

---@type bufnr[]
local gl_mut_bufnrs = {}

---@type bufnr
local gl_mut_current_vidx

local gl_mut_valid_pick_letters =
  'asdfjkl;ghnmxcvbziowerutyqpASDFJKLGHNMXCVBZIOWERUTYQP'

local gl_mut_taken_pick_letters = {}

---@diagnostic disable: duplicate-doc-class

---@alias vidx  number
---@alias index  number
---@alias bufnr  number

---@class Buffer
---@field _vidx         vidx
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
  local is_windows = not vim_fn.has('win32') == 0

  -- FIXME: it appears in windows sometimes directories are separated by '/'
  -- instead of '\\'??
  if is_windows then
    buffers = vim_map(function(buffer)
      buffer.path = buffer.path:gsub('/', '\\')
      return buffer
    end, buffers)
  end

  local path_separator = not is_windows and '/' or '\\'

  local paths = vim_map(function(buffer)
    return vim_fn.reverse(vim_split(buffer.path, path_separator))
  end, buffers)

  local prefixes = vim_map(function() return {} end, buffers)

  for i=1,#paths do
    for j=i+1,#paths do
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
      #prefixes[i] == #paths[i] and path_separator or '',
      vim_fn.join(vim_fn.reverse(prefixes[i]), path_separator),
      #prefixes[i] > 0 and path_separator or '',
    })
  end

  return buffers
end

---@param filename  string
---@param bufnr  bufnr
---@return string
local get_pick_letter = function(filename, bufnr)
  if gl_mut_taken_pick_letters[bufnr] then
    return gl_mut_taken_pick_letters[bufnr]
  end

  local init_letter = filename:sub(1, 1)
  if gl_mut_valid_pick_letters:find(init_letter) then
    gl_mut_valid_pick_letters = gl_mut_valid_pick_letters:gsub(init_letter, '')
    gl_mut_taken_pick_letters[bufnr] = init_letter
    return init_letter
  end

  if #gl_mut_valid_pick_letters > 0 then
    local first_valid = gl_mut_valid_pick_letters:sub(1, 1)
    gl_mut_valid_pick_letters = gl_mut_valid_pick_letters:sub(2)
    gl_mut_taken_pick_letters[bufnr] = first_valid
    return first_valid
  end

  return '?'
end

---@param path  string
---@param filename  string
---@param type  string
---@return table<string, string>
local get_devicon = function(path, filename, type)
  local name = (type == 'terminal') and 'terminal' or filename
  local extn = vim_fn.fnamemodify(path, ':e')
  local icon, color = rq_devicons.get_icon_color(name, extn, {default = true})
  return {
    icon = icon .. ' ',
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

  local _vidx = -1
  local index = -1
  local number = b.bufnr
  local type = opts.buftype
  local is_focused = (number == vim_fn.bufnr('%'))
  local is_modified = opts.modified
  local is_readonly = opts.readonly
  local path = b.name
  local unique_prefix = ''

  local filename =
    (type == 'quickfix' and 'quickfix')
    or (#path > 0 and vim_fn.fnamemodify(path, ':t'))
    or '[No Name]'

  local filetype =
    not (b.variables and b.variables.netrw_browser_active)
    and opts.filetype
     or 'netrw'

  local pick_letter =
    filename ~= '[No Name]'
    and get_pick_letter(filename, number)
     or '?'

  local devicon =
    has_devicons
    and get_devicon(path, filename, type)
     or {icon = '', color = ''}

  local diagns = get_diagnostics(number)

  return {
    _vidx = _vidx,
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
  return vim_contains(gl_mut_bufnrs, buffer.number)
end

---@param buffer  Buffer
---@return boolean
local is_new = function(buffer)
  return not vim_contains(gl_mut_bufnrs, buffer.number)
end

---Sorter used to open new buffers at the end of the bufferline.
---@param vidxs  vidx[]
---@param current_vidx  vidx
---@return fun(buffer1: Buffer, buffer2: Buffer): boolean
local sort_by_new_after_last = function(vidxs, current_vidx)
  ---@param buffer1  Buffer
  ---@param buffer2  Buffer
  ---@return boolean
  return function(buffer1, buffer2)
    if is_old(buffer1) and is_old(buffer2) then
      return vidxs[buffer1.number] < vidxs[buffer2.number]

    elseif is_old(buffer1) and is_new(buffer2) then
      return true

    elseif is_new(buffer1) and is_old(buffer2) then
      return false

    else
      return buffer1.number < buffer2.number
    end
  end
end

---Sorter used to open new buffers next to the current buffer.
---@param vidxs  vidx[]
---@param current_vidx  vidx
---@return fun(buffer1: Buffer, buffer2: Buffer): boolean
local sort_by_new_after_current = function(vidxs, current_vidx)
  ---@param buffer1  Buffer
  ---@param buffer2  Buffer
  ---@return boolean
  return function(buffer1, buffer2)
    if is_old(buffer1) and is_old(buffer2) then
      -- If both buffers are either before or after (inclusive) the current
      -- buffer then respect the current order.
      if (vidxs[buffer1.number] - current_vidx)
          * (vidxs[buffer2.number] - current_vidx) >= 0 then
        return vidxs[buffer1.number] < vidxs[buffer2.number]
      end
      return vidxs[buffer1.number] < current_vidx

    elseif is_old(buffer1) and is_new(buffer2) then
      return vidxs[buffer1.number] <= current_vidx

    elseif is_new(buffer1) and is_old(buffer2) then
      return vidxs[buffer2.number] > current_vidx

    else
      return buffer1.number < buffer2.number
    end
  end
end

---@param vidx1  vidx
---@param vidx2  vidx
local switch_bufnrs_order = function(vidx1, vidx2)
  gl_mut_bufnrs[vidx1], gl_mut_bufnrs[vidx2] =
    gl_mut_bufnrs[vidx2], gl_mut_bufnrs[vidx1]
  vim_cmd('redrawtabline')
end

---@return Buffer[]
local get_valid_buffers = function()
  local buffers = vim_map(function(b)
    return new_buffer(b)
  end, vim_fn.getbufinfo({buflisted = 1}))

  buffers = vim_filter(function(buffer)
    return buffer.filetype ~= 'netrw'
  end, buffers)

  local valid_buffers = compute_unique_prefixes(
    not gl_settings.filter_valid
    and buffers
     or vim_filter(gl_settings.filter_valid, buffers)
  )

  local vidxs = {}
  for i, bufnr in ipairs(gl_mut_bufnrs) do
    vidxs[bufnr] = i
  end

  tbl_sort(valid_buffers, gl_buffer_sorter(vidxs, gl_mut_current_vidx))

  gl_mut_bufnrs = {}
  for i, buffer in ipairs(valid_buffers) do
    buffer._vidx = i
    gl_mut_bufnrs[i] = buffer.number
    if buffer.is_focused then gl_mut_current_vidx = i end
  end

  rq_mappings.set_valid_buffers(valid_buffers)

  return valid_buffers
end

---@return Buffer[]
local get_visible_buffers = function()
  local valid_buffers = get_valid_buffers()

  local visible_buffers =
    not gl_settings.filter_visible
    and valid_buffers
     or vim_filter(gl_settings.filter_visible, valid_buffers)

  for i, buffer in ipairs(visible_buffers) do
    buffer.index = i
  end

  rq_mappings.set_visible_buffers(visible_buffers)

  return visible_buffers
end

---@param settings  table
local setup = function(settings)
  gl_settings = settings
  gl_buffer_sorter =
    (settings.new_buffers_position == 'last' and sort_by_new_after_last)
     or (settings.new_buffers_position == 'next' and sort_by_new_after_current)
end

return {
  switch_bufnrs_order = switch_bufnrs_order,
  get_valid_buffers = get_valid_buffers,
  get_visible_buffers = get_visible_buffers,
  setup = setup,
}
