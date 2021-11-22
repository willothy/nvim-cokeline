local has_devicons, devicons = pcall(require, 'nvim-web-devicons')

local sort = table.sort

local diagnostics = vim.diagnostic or vim.lsp.diagnostic
local contains = vim.tbl_contains
local filter = vim.tbl_filter
local split = vim.split
local map = vim.tbl_map
local bopt = vim.bo
local fn = vim.fn

local settings, current_bufnr, bufnrs, revlookup

local M = {}

---@class buffer
---@field order         number
---@field index         number
---@field number        number
---@field type          string
---@field is_focused    boolean
---@field is_modified   boolean
---@field is_readonly   boolean
---@field path          string
---@field unique_prefix string
---@field filename      string
---@field filetype      string
---@field devicon       devicon
---@field diagnostics   diagnostics

---@class devicon
---@field icon  string
---@field color string

---@class diagnostics
---@field errors    number
---@field warnings  number
---@field infos     number
---@field hints     number

---@param path      string
---@param filename  string
---@param type      string
---@return devicon
local get_devicon = function(path, filename, type)
  local name = (type == 'terminal') and 'terminal' or filename
  local extn = fn.fnamemodify(path, ':e')
  local icon, color = devicons.get_icon_color(name, extn, {default = true})
  return {
    icon = icon .. ' ',
    color = color,
  }
end

---@param bufnr number
---@return diagnostics
local get_diagnostics = function(bufnr)
  local diagns = diagnostics.get(bufnr)
  return {
    errors   = #filter(function(d) return d.severity == 1 end, diagns),
    warnings = #filter(function(d) return d.severity == 2 end, diagns),
    infos    = #filter(function(d) return d.severity == 3 end, diagns),
    hints    = #filter(function(d) return d.severity == 4 end, diagns),
  }
end

---@param  valid_buffers buffer[]
---@return buffer[] valid_buffers
local compute_unique_prefixes = function(valid_buffers)
  -- FIXME: it appears in windows sometimes neovim reports directories
  -- separated by '/' instead of '\\'??
  if not fn.has('win32') == 0 then
    valid_buffers = map(function(buffer)
      buffer.path = buffer.path:gsub('/', '\\')
      return buffer
    end, valid_buffers)
  end

  local path_separator = (fn.has('win32') == 0) and '/' or '\\'

  local paths = map(function(buffer)
    return fn.reverse(split(buffer.path, path_separator))
  end, valid_buffers)

  local prefixes = map(function() return {} end, valid_buffers)

  -- FIXME: mutating
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

  for i, buffer in ipairs(valid_buffers) do
    -- FIXME: mutating
    buffer.unique_prefix =
      (#prefixes[i] == #paths[i] and path_separator or '')
      .. fn.join(fn.reverse(prefixes[i]), path_separator)
      .. (#prefixes[i] > 0 and path_separator or '')
  end

  return valid_buffers
end

---@param b table
---@return buffer
local new_buffer = function(b)
  local opts = bopt[b.bufnr]

  local order = -1
  local index = -1
  local number = b.bufnr
  local type = opts.buftype
  local is_focused = (number == fn.bufnr('%'))
  local is_modified = opts.modified
  local is_readonly = opts.readonly
  local path = b.name
  local unique_prefix = ''

  local filename =
    (type == 'quickfix' and 'quickfix')
    or (#path > 0 and fn.fnamemodify(path, ':t'))
    or '[No Name]'

  local filetype =
    not (b.variables and b.variables.netrw_browser_active)
    and opts.filetype
     or 'netrw'

  local devicon =
    has_devicons
    and get_devicon(path, filename, type)
     or {icon = '', color = ''}

  local diagns = get_diagnostics(number)

  return {
    order = order,
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
    devicon = devicon,
    diagnostics = diagns,
  }
end

---@param bufnr_order number[]
local update_bufnrs = function(bufnr_order)
  bufnrs = bufnr_order
  -- Add a reverse lookup for the buffer numbers (bufnr -> index).
  revlookup = {}
  for i, bufnr in pairs(bufnr_order) do
    revlookup[bufnr] = i
  end
end

---@param buffer buffer
---@return boolean
local is_old = function(buffer) return contains(bufnrs, buffer.number) end

---@param buffer buffer
---@return boolean
local is_new = function(buffer) return not is_old(buffer) end

---@param buffer1 buffer
---@param buffer2 buffer
---@return boolean
local sort_by_longevity = function(buffer1, buffer2)
  if is_old(buffer1) and is_old(buffer2) then
    return revlookup[buffer1.number] < revlookup[buffer2.number]

  elseif is_old(buffer1) and is_new(buffer2) then
    return true

  elseif is_new(buffer1) and is_old(buffer2) then
    return false

  else
    return buffer1.number < buffer2.number
  end
end

---@param buffer1 buffer
---@param buffer2 buffer
---@return boolean
local sort_by_new_after_current = function(buffer1, buffer2)
  if is_old(buffer1) and is_old(buffer2) then
    -- If both buffers are either before or after (inclusive) the current
    -- buffer then respect the current order.
    if (revlookup[buffer1.number] - revlookup[current_bufnr])
        * (revlookup[buffer2.number] - revlookup[current_bufnr]) >= 0 then
      return revlookup[buffer1.number] < revlookup[buffer2.number]
    end
    return revlookup[buffer1.number] < revlookup[current_bufnr]

  elseif is_old(buffer1) and is_new(buffer2) then
    return revlookup[buffer1.number] <= revlookup[current_bufnr]

  elseif is_new(buffer1) and is_old(buffer2) then
    return revlookup[buffer2.number] > revlookup[current_bufnr]

  else
    return buffer1.number < buffer2.number
  end
end

---@param bufnr_order number[]
---@return buffer[], buffer[]
M.get_bufinfos = function(bufnr_order)
  -- FIXME: mutating
  update_bufnrs(bufnr_order)

  local listed_buffers = fn.getbufinfo({buflisted = 1})

  local buffers = map(function(b)
    return new_buffer(b)
  end, listed_buffers)

  local valid = compute_unique_prefixes(filter(function(buffer)
    return buffer.filetype ~= 'netrw'
  end, buffers))

  local sorter =
    (settings.new_buffers_position == 'last' and sort_by_longevity)
     or (settings.new_buffers_position == 'next' and sort_by_new_after_current)

  -- FIXME: mutating
  sort(valid, sorter)

  -- FIXME: mutating
  for i, buffer in ipairs(valid) do
    buffer.order = i
    if buffer.is_focused then current_bufnr = buffer.number end
  end

  local visible =
    not settings.filter and valid
     or filter(function(buffer) return settings.filter(buffer) end, valid)

  -- FIXME: mutating
  for i, buffer in ipairs(visible) do
    buffer.index = i
  end

  return valid, visible
end

---@param settngs table
M.setup = function(settngs)
  settings = settngs
end

return M
