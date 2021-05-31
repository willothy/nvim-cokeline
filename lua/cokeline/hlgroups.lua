local concat = table.concat
local insert = table.insert
local format = string.format
local tohex = bit.tohex
local vimcmd = vim.cmd
local nvim_get_hl_by_name = vim.api.nvim_get_hl_by_name

local M = {}

local Hlgroup = {
  name = '',
  opts = {},
}

function Hlgroup:embed(text)
  return format('%%#%s#%s%%*', self.name, text)
end

function Hlgroup:exec()
  local hilight_fmt = 'highlight! %s %s'
  local opt_fmt = '%s=%s'
  local opts = {}
  for k, v in pairs(self.opts) do
    insert(opts, opt_fmt:format(k, v))
  end
  vimcmd(hilight_fmt:format(self.name, concat(opts, ' ')))
end

function Hlgroup:new(name, opts)
  hlgroup = {}
  setmetatable(hlgroup, self)
  self.__index = self
  if name then
    hlgroup.name = name
  end
  if opts then
    hlgroup.opts = opts
  end
  hlgroup:exec()
  return hlgroup
end

-- Given a highlight group name and an attribute (either 'fg' for the
-- foreground or 'bg' for the background), return the color set for that
-- particular attribute by the current colorscheme in hexadecimal format.
function M.get_hex(hlgroup, attribute)
  assert(attribute == 'fg' or attribute == 'bg')
  attribute =
    attribute == 'fg'
    and 'foreground'
     or 'background'

  -- TODO: not sure why this fails if I call the 'nvim_get_hl_by_name' function
  -- directly instead of through a pcall.
  local _, hldef = pcall(nvim_get_hl_by_name, hlgroup, true)
  if hldef and hldef[attribute] then
    return format('#%s', tohex(hldef[attribute], 6))
  end

  -- TODO: nvim-bufferline handles a couple of fallbacks here in case
  -- 'nvim_get_hl_by_name' doesn't find a color for the given attribute.

  return 'NONE'
end

function M.setup(settings)
  local highlights = settings.highlights

  local hlgroups = {
    fill = Hlgroup:new('TabLineFill', {guibg = highlights.fill}),

    focused = {
      title = Hlgroup:new(
        'CokeFocused',
        {guifg = highlights.focused_fg, guibg = highlights.focused_bg}),

      modified = Hlgroup:new(
        'CokeModifiedFocused',
        {guifg = highlights.modified, guibg = highlights.focused_bg}),

      readonly = Hlgroup:new(
        'CokeReadonlyFocused',
        {guifg = highlights.readonly, guibg = highlights.focused_bg}),
    },

    unfocused = {
      title = Hlgroup:new(
        'CokeUnfocused',
        {guifg = highlights.unfocused_fg, guibg = highlights.unfocused_bg}),

      modified = Hlgroup:new(
        'CokeModifiedUnfocused',
        {guifg = highlights.modified, guibg = highlights.unfocused_bg}),

      readonly = Hlgroup:new(
        'CokeReadonlyUnfocused',
        {guifg = highlights.readonly, guibg = highlights.unfocused_bg}),
    },
  }

  if settings.show_devicons then
    hlgroups.focused['devicons'] = {}
    hlgroups.unfocused['devicons'] = {}
    local devicons = require('nvim-web-devicons').get_icons()

    for _, icon in pairs(devicons) do
      hlgroups.focused.devicons[icon.icon] = Hlgroup:new(
        format('CokeDevIcon%sFocused', icon.name),
        {guifg = icon.color, guibg = highlights.focused_bg})

      hlgroups.unfocused.devicons[icon.icon] = Hlgroup:new(
        format('CokeDevIcon%sUnfocused', icon.name),
        {guifg = icon.color, guibg = highlights.unfocused_bg})
    end
  end

  settings['hlgroups'] = hlgroups
  return settings
end

return M
