local format = string.format
local concat = table.concat
local insert = table.insert
local tohex = bit.tohex

local get_hl_by_name = vim.api.nvim_get_hl_by_name
local cmd = vim.cmd

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
  cmd(hilight_fmt:format(self.name, concat(opts, ' ')))
end

function Hlgroup:new(args)
  local hlgroup = {}
  setmetatable(hlgroup, self)
  self.__index = self
  if args.name then
    hlgroup.name = args.name
  end
  if args.opts then
    hlgroup.opts = args.opts
  end
  hlgroup:exec()
  return hlgroup
end

-- Given a highlight group name and an attribute (either 'fg' for the
-- foreground or 'bg' for the background), return the color set by the current
-- colorscheme for that particular attribute in hexadecimal format.
function M.get_hex(hlgroup, attribute)
  assert(attribute == 'fg' or attribute == 'bg')
  attribute =
    attribute == 'fg'
    and 'foreground'
     or 'background'

  -- TODO: not sure why this fails if I call the 'get_hl_by_name' function
  -- directly instead of through a pcall.
  local _, hldef = pcall(get_hl_by_name, hlgroup, true)
  if hldef and hldef[attribute] then
    return format('#%s', tohex(hldef[attribute], 6))
  end

  -- TODO: nvim-bufferline handles a couple of fallbacks here in case
  -- 'get_hl_by_name' doesn't find a color for the given attribute.

  return 'NONE'
end

function M.setup(settings)
  local highlights = settings.highlights

  local hlgroups = {
    fill = Hlgroup:new({
      name = 'TabLineFill',
      opts = {guibg = highlights.fill},
    }),

    focused = {
      title = Hlgroup:new({
        name = 'CokeFocused',
        opts = {
          guifg = highlights.focused_fg,
          guibg = highlights.focused_bg,
        },
      }),

      unique = Hlgroup:new({
        name = 'CokeUniqueFocused',
        opts = {
          gui = 'italic',
          guifg = highlights.unique_fg,
          guibg = highlights.focused_bg,
        },
      }),

      modified = Hlgroup:new({
        name = 'CokeModifiedFocused',
        opts = {
          guifg = highlights.modified,
          guibg = highlights.focused_bg,
        },
      }),

      readonly = Hlgroup:new({
        name = 'CokeReadonlyFocused',
        opts = {
          guifg = highlights.readonly,
          guibg = highlights.focused_bg,
        },
      }),
    },

    unfocused = {
      title = Hlgroup:new({
        name = 'CokeUnfocused',
        opts = {
          guifg = highlights.unfocused_fg,
          guibg = highlights.unfocused_bg,
        },
      }),

      unique = Hlgroup:new({
        name = 'CokeUniqueUnfocused',
        opts = {
          gui = 'italic',
          guifg = highlights.unique_fg,
          guibg = highlights.unfocused_bg,
        },
      }),

      modified = Hlgroup:new({
        name = 'CokeModifiedUnfocused',
        opts = {
          guifg = highlights.modified,
          guibg = highlights.unfocused_bg,
        },
      }),

      readonly = Hlgroup:new({
        name = 'CokeReadonlyUnfocused',
        opts = {
          guifg = highlights.readonly,
          guibg = highlights.unfocused_bg,
        },
      }),
    },
  }

  if settings.show_devicons then
    hlgroups.focused['devicons'] = {}
    hlgroups.unfocused['devicons'] = {}
    local devicons = require('nvim-web-devicons').get_icons()

    for _, icon in pairs(devicons) do
      hlgroups.focused.devicons[icon.icon] = Hlgroup:new({
        name = format('CokeDevIcon%sFocused', icon.name),
        opts = {guifg = icon.color, guibg = highlights.focused_bg},
      })

      hlgroups.unfocused.devicons[icon.icon] = Hlgroup:new({
        name = format('CokeDevIcon%sUnfocused', icon.name),
        opts = {guifg = icon.color, guibg = highlights.unfocused_bg},
      })
    end
  end

  settings['hlgroups'] = hlgroups
  return settings
end

return M
