local has_devicons, devicons = pcall(require, 'nvim-web-devicons')

local sort = table.sort

local diagnostics = vim.diagnostic or vim.lsp.diagnostic
local contains = vim.tbl_contains
local filter = vim.tbl_filter
local split = vim.split
local map = vim.tbl_map
local bopt = vim.bo
local cmd = vim.cmd
local opt = vim.opt
local fn = vim.fn

---WARNING(state): this variable is used as global immutable state
---@type table
local settings

---WARNING(state,mutable): this variable is used as global mutable state
---@type Buffer[]
local valid_buffers = {}

---WARNING(state,mutable): this variable is used as global mutable state
---@type Buffer[]
local visible_buffers = {}

---WARNING(state,mutable): this variable is used as global mutable state
---@type bufnr[]
local bufnrs = {}

---WARNING(state,mutable): this variable is used as global mutable state
---@type vidx[]
local vidxs = {}

---WARNING(state,mutable): this variable is used as global mutable state
---@type bufnr
local current_bufnr

local compute_unique_prefixes = function()
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
    buffer.unique_prefix =
      (#prefixes[i] == #paths[i] and path_separator or '')
      .. fn.join(fn.reverse(prefixes[i]), path_separator)
      .. (#prefixes[i] > 0 and path_separator or '')
  end
end

---@param path  string
---@param filename  string
---@param type  string
---@return table<string, string>
local get_devicon = function(path, filename, type)
  local name = (type == 'terminal') and 'terminal' or filename
  local extn = fn.fnamemodify(path, ':e')
  local icon, color = devicons.get_icon_color(name, extn, {default = true})
  return {
    icon = icon .. ' ',
    color = color,
  }
end

---@param bufnr  bufnr
---@return table<string, number>
local get_diagnostics = function(bufnr)
  local diagns = diagnostics.get(bufnr)
  return {
    errors = #filter(function(d) return d.severity == 1 end, diagns),
    warnings = #filter(function(d) return d.severity == 2 end, diagns),
    infos = #filter(function(d) return d.severity == 3 end, diagns),
    hints = #filter(function(d) return d.severity == 4 end, diagns),
  }
end

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
---@field devicon       table<string, string>
---@field diagnostics   table<string, number>

---@param b  table
---@return Buffer
local new_buffer = function(b)
  local opts = bopt[b.bufnr]

  local _vidx = -1
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
    devicon = devicon,
    diagnostics = diagns,
  }
end

---@param buffer  Buffer
---@return boolean
local is_old = function(buffer) return contains(bufnrs, buffer.number) end

---@param buffer  Buffer
---@return boolean
local is_new = function(buffer) return not is_old(buffer) end

---Sorter used to open new buffers at the end of the bufferline.
---@param buffer1  Buffer
---@param buffer2  Buffer
---@return boolean
local sort_by_new_after_last = function(buffer1, buffer2)
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

---Sorter used to open new buffers next to the current buffer.
---@param buffer1  Buffer
---@param buffer2  Buffer
---@return boolean
local sort_by_new_after_current = function(buffer1, buffer2)
  if is_old(buffer1) and is_old(buffer2) then
    -- If both buffers are either before or after (inclusive) the current
    -- buffer then respect the current order.
    if (vidxs[buffer1.number] - vidxs[current_bufnr])
        * (vidxs[buffer2.number] - vidxs[current_bufnr]) >= 0 then
      return vidxs[buffer1.number] < vidxs[buffer2.number]
    end
    return vidxs[buffer1.number] < vidxs[current_bufnr]

  elseif is_old(buffer1) and is_new(buffer2) then
    return vidxs[buffer1.number] <= vidxs[current_bufnr]

  elseif is_new(buffer1) and is_old(buffer2) then
    return vidxs[buffer2.number] > vidxs[current_bufnr]

  else
    return buffer1.number < buffer2.number
  end
end

---Takes in a list of buffer numbers (used to determine if some buffers have
---been switched around), returns the currently listed valid buffers.
---@param bufnrs_  bufnr[]
local get_valid_buffers = function(bufnrs_)
  local buffers = map(function(b)
    return new_buffer(b)
  end, fn.getbufinfo({buflisted = 1}))

  valid_buffers = filter(function(buffer)
    return buffer.filetype ~= 'netrw'
  end, buffers)

  compute_unique_prefixes()

  local sorter =
    (settings.new_buffers_position == 'last' and sort_by_new_after_last)
     or (settings.new_buffers_position == 'next' and sort_by_new_after_current)

  vidxs = {}
  for i, bufnr in ipairs(bufnrs_) do
    vidxs[bufnr] = i
  end

  sort(valid_buffers, sorter)

  bufnrs = {}
  for i, buffer in ipairs(valid_buffers) do
    buffer._vidx = i
    bufnrs[i] = buffer.number
    if buffer.is_focused then current_bufnr = buffer.number end
  end

  return valid_buffers
end

---@return Buffer[]
local get_visible_buffers = function()
  valid_buffers = get_valid_buffers(bufnrs)

  visible_buffers =
    not settings.filter
    and valid_buffers
     or filter(function(buffer)
          return settings.filter(buffer)
        end, valid_buffers)

  for i, buffer in ipairs(visible_buffers) do
    buffer.index = i
  end

  return visible_buffers
end



---Returns the valid index of the currently focused buffer (if there is one in
---`valid_buffers`).
---@return vidx|nil
local get_current_vidx = function()
  for _, buffer in pairs(valid_buffers) do
    if buffer.is_focused then return buffer._vidx end
  end
end

---Returns a valid index from the valid index of the currently focused buffer
---and a step (either +1 or -1).
---@param current  vidx
---@param step  '-1'|'1'
---@return vidx|nil
local get_vidx_from_step = function(current, step)
  local target = current + step
  if target < 1 or target > #valid_buffers then
    if not settings.cycle_prev_next_mappings then return end
    return (target - 1) % #valid_buffers + 1
  end
  return target
end

---@param index index
---@return vidx|nil
local get_vidx_from_index = function(index)
  for _, buffer in pairs(visible_buffers) do
    if buffer.index == index then return buffer._vidx end
  end
end

---@param vidx1 vidx
---@param vidx2 vidx
local switch_buffer_order = function(vidx1, vidx2)
  valid_buffers[vidx1], valid_buffers[vidx2]
    = valid_buffers[vidx2], valid_buffers[vidx1]
  cmd('redrawtabline | redraw')
end

---@param index index
local switch_by_index = function(index)
  local current = get_current_vidx()
  if not current then return end
  local target = get_vidx_from_index(index)
  if not target then return end
  switch_buffer_order(current, target)
end

---@param step '-1'|'1'
local switch_by_step = function(step)
  if opt.showtabline._value == 0 then
    valid_buffers = get_valid_buffers(bufnrs)
  end
  local current = get_current_vidx()
  if not current then return end
  local target = get_vidx_from_step(current, step)
  if not target then return end
  switch_buffer_order(current, target)
end

---@param bufnr bufnr
local focus_buffer = function(bufnr)
  cmd('buffer ' .. bufnr)
end

---@param index index
local focus_by_index = function(index)
  local target = get_vidx_from_index(index)
  if not target then return end
  focus_buffer(valid_buffers[target].number)
end

---@param step '-1'|'1'
local focus_by_step = function(step)
  if opt.showtabline._value == 0 then
    valid_buffers = get_valid_buffers(bufnrs)
  end
  local current = get_current_vidx()
  if not current then return end
  local target = get_vidx_from_step(current, step)
  if not target then return end
  focus_buffer(valid_buffers[target].number)
end

local toggle = function()
  local listed_buffers = fn.getbufinfo({buflisted = 1})
  opt.showtabline = (#listed_buffers > 0) and 2 or 0
end



---@param settings_  table
local setup = function(settings_, cycle_prev_next_mappings)
  settings = settings_
  settings.cycle_prev_next_mappings = cycle_prev_next_mappings
end

return {
  get_visible_buffers = get_visible_buffers,
  switch_by_index = switch_by_index,
  switch_by_step = switch_by_step,
  focus_by_index = focus_by_index,
  focus_by_step = focus_by_step,
  toggle = toggle,
  setup = setup,
}
