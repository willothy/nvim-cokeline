local concat = table.concat
local insert = table.insert
local vimcmd = vim.cmd

local M = {}

local Hlgroup = {
  name = '',
  opts = {},
}

function Hlgroup:embed(str)
  local fmt = '%%#%s#%s%%*'
  return fmt:format(self.name, str)
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

function M.setup(settings)
  local hilights = settings.hilights
  local hlgroups = {}

  hlgroups['fill'] = Hlgroup:new(
    'TabLineFill',
    {
      guibg = hilights.fill.bg,
    }
  )

  hlgroups['titles'] = {
    focused = Hlgroup:new(
      'CokeTitleFocused',
      {
        guifg = hilights.titles.focused.fg,
        guibg = hilights.titles.focused.bg,
      }
    ),
    unfocused = Hlgroup:new(
      'CokeTitleUnfocused',
      {
        guifg = hilights.titles.unfocused.fg,
        guibg = hilights.titles.unfocused.bg,
      }
    ),
  }

  hlgroups['symbols'] = {
    separator = Hlgroup:new(
      'CokeTitleSeparator',
      {
        guifg = hilights.symbols.separator.fg,
        guibg = hilights.symbols.separator.bg,
      }
    ),
  }

  if settings.show_devicons then
    hlgroups['devicons'] = {}
    local devicons = require('nvim-web-devicons').get_icons()
    local fmt = {
      focused = 'CokeDevIcon%sFocused',
      unfocused = 'CokeDevIcon%sUnfocused',
    }
    for _, icon in pairs(devicons) do
      hlgroups.devicons[icon.icon] = {
        focused = Hlgroup:new(
          fmt.focused:format(icon.name),
          {
            guifg = icon.color,
            guibg = hilights.titles.focused.bg,
          }
        ),
        unfocused = Hlgroup:new(
          fmt.unfocused:format(icon.name),
          {
            guifg = icon.color,
            guibg = hilights.titles.unfocused.bg,
          }
        ),
      }
    end
  end

  settings['hlgroups'] = hlgroups
  return settings
end

return M
