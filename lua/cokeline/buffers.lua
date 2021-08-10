local holders = require('cokeline/defaults').line_placeholders

local has_devicons, devicons = pcall(require, 'nvim-web-devicons')
local get_icon
if has_devicons then
  devicons.setup({default = true})
  get_icon = devicons.get_icon
end

local format = string.format
local reverse = string.reverse
local concat = table.concat
local insert = table.insert

local contains = vim.tbl_contains
local filter = vim.tbl_filter
local map = vim.tbl_map
local fn = vim.fn

local Buffer = {
  number = 0,
  index = 0,
  path = '',
  type = '',
  is_focused = false,
  is_modified = false,
  is_readonly = false,
  title = ''
}

local M = {}

local function fix_hl_syntax(title, component)
  -- The Vim syntax to embed a string 'foo' in a custom highlight group 'HL' is
  -- to return '%#HL#foo%*', where the closing '%*' ends *all* highlight groups
  -- opened up to that point.

  -- This is annoying because if one starts a highlight group called 'HLa',
  -- then another one called 'HLb', there's no way to end 'HLb' without also
  -- ending 'HLa'.

  -- This function fixes that by taking in the text with the broken syntax and
  -- the component that broke it, and it:
  --   1. finds the highlight group that was active before the component;
  --   2. ends it;
  --   3. restarts it after the component.

  -- In short, we take in '%#HLa#foo%#HLb#bar%*baz%*' and '%#HLb#bar%*'
  --                       \________HLa_______/
  --                                \___HLb___/
  -- and we return '%#HLa#foo%*%#HLb#bar%*%#HLa#baz%*'.
  --                \___HLa___/\___HLb___/\___HLa___/

  local before, after = title:match(
    format('(.*)%s(.*)', component:gsub('([^%w])', '%%%1'))
  )
  local active_hlgroup = before:gsub('.*%%#([^#]*)#.*', '%1')
  return format('%s%%*%s%%#%s#%s', before, component, active_hlgroup, after)
end

local function get_unique_path(filename)
  -- Taken from github.com/famiu/feline.nvim

  local listed_buffers = fn.getbufinfo({buflisted = 1})
  local filenames = map(function(b) return b.name end, listed_buffers)
  local other_filenames = filter(
    function(f) return filename ~= f end,
    filenames
  )

  if #other_filenames == 0 then
    return fn.fnamemodify(filename, ':t')
  end

  filename = reverse(filename)
  other_filenames = map(reverse, other_filenames)

  local index = math.max(unpack(map(
    function(f)
      for i = 1, #f do
        if filename:sub(i, i) ~= f:sub(i, i) then
          return i
        end
      end
      return 1
    end,
    other_filenames
  )))

  local path_separator = '/'

  while index <= #filename do
    if filename:sub(index, index) == path_separator then
      index = index - 1
      break
    end

    index = index + 1
  end

  local aux = filename:sub(1, index)
  return reverse(aux:sub(#fn.fnamemodify(reverse(filename), ':t') + 1, #aux))
end

function Buffer:embed_in_clickable_region()
  self.title = format('%%%s@cokeline#handle_click@%s', self.number, self.title)
end

function Buffer:render_devicon(hlgroups)
  local filename =
    self.type == 'terminal'
     and 'terminal'
      or fn.fnamemodify(self.path, ':t')
  local extension = fn.fnamemodify(self.path, ':e')
  local icon, _ = get_icon(filename, extension)
  local devicon = hlgroups[icon]:embed(format('%s ', icon))
  self.title = self.title:gsub(holders.devicon, devicon:gsub('%%', '%%%%'))
  self.title = fix_hl_syntax(self.title, devicon)
end

function Buffer:render_index(index)
  self.title = self.title:gsub(holders.index, index)
end

function Buffer:render_filename(hlgroup_unique)
  local filename
  local unique_path

  if self.type == 'quickfix' then
    filename = '[Quickfix List]'
  elseif #self.path > 0 then
    filename = fn.fnamemodify(self.path, ':t')
    -- Escape any percent signs in the filename
    if filename:match('%%') then
      filename = filename:gsub('%%', '%%%%%%%%')
    end
    -- Prepend a unique path to the filename if there are multiple buffers
    -- with the same filename.
    unique_path = get_unique_path(self.path)
    if unique_path ~= '' then
      filename = hlgroup_unique:embed(unique_path):gsub('%%', '%%%%') .. filename
    end
  else
    filename = '[No Name]'
  end

  self.title = self.title:gsub(holders.filename, filename)
  if unique_path ~= '' then
    self.title = fix_hl_syntax(self.title, hlgroup_unique:embed(unique_path))
  end
end

function Buffer:render_flags(
      symbol_modified,
      symbol_readonly,
      hlgroup_modified,
      hlgroup_readonly,
      flags_fmt,
      divider
    )

  if not (self.is_modified or self.is_readonly) then
    self.title = self.title:gsub(holders.flags, '')
    return
  end

  local symbols = {}
  if self.is_modified then
    insert(symbols, hlgroup_modified:embed(symbol_modified))
  end
  if self.is_readonly then
    insert(symbols, hlgroup_readonly:embed(symbol_readonly))
  end

  local flags = concat(symbols, divider)
  local flags_fmtd = flags_fmt:gsub(holders.flags, flags:gsub('%%', '%%%%'))
  self.title = self.title:gsub(holders.flags, flags_fmtd:gsub('%%', '%%%%'))
  self.title = fix_hl_syntax(self.title, flags)
end

function Buffer:render_close_button(close_button_symbol)
  local close_button = format(
    '%%%s@cokeline#close_button_handle_click@%s%%%s@cokeline#handle_click@',
    self.number,
    close_button_symbol,
    self.number)
  self.title = self.title:gsub(
    holders.close_button, close_button:gsub('%%', '%%%%'))
end

function Buffer:new(args)
  local buffer = {}
  setmetatable(buffer, self)
  self.__index = self
  if args.bufnr then
    buffer.number = args.bufnr
    buffer.type = vim.bo[args.bufnr].buftype
    buffer.is_focused = args.bufnr == fn.bufnr('%')
    buffer.is_modified = vim.bo[args.bufnr].modified
    buffer.is_readonly = vim.bo[args.bufnr].readonly
  end
  if args.name then
    buffer.path = args.name
  end
  return buffer
end

function M.get_listed(order)
  local listed_buffers = fn.getbufinfo({buflisted = 1})

  if not next(order) then
    return map(function(b) return Buffer:new(b) end, listed_buffers)
  end

  local buffers = {}
  local buffer_numbers = {}

  -- First add the buffers whose numbers are in the global 'order' table that
  -- are still listed.
  for _, number in ipairs(order) do
    for _, b in pairs(listed_buffers) do
      if b.bufnr == number then
        insert(buffers, Buffer:new(b))
        insert(buffer_numbers, number)
        break
      end
    end
  end

  -- Then add all the listed buffers whose numbers are not yet in the global
  -- 'order' table.
  for _, b in pairs(listed_buffers) do
    if not contains(buffer_numbers, b.bufnr) then
      insert(buffers, Buffer:new(b))
    end
  end

  return buffers
end

return M
