local format = string.format
local vimcmd = vim.cmd
local M = {}

local function create_hlgroups(hlgroups)
  local cmd
  for _, hlgroup in pairs(hlgroups) do
    cmd = 'highlight! ' .. hlgroup.name
    for k, v in pairs(hlgroup) do
      -- TODO: this could be cleaner
      if k ~= 'name' then
        cmd = format('%s %s=%s', cmd, k, v)
      end
    end
    vimcmd(cmd)
  end
end

function M.setup(settings)
  local hilights = settings.hilights
  local hlgroups = {
    {
      name = 'TabLineFill',
      guibg = hilights.fill.bg,
    },
    {
      name = 'CokeFocused',
      guibg = hilights.buffers.focused.bg,
      guifg = hilights.buffers.focused.fg,
    },
    {
      name = 'CokeUnfocused',
      guibg = hilights.buffers.unfocused.bg,
      guifg = hilights.buffers.unfocused.fg,
    },
  }
  if settings.show_devicons then
    local devicons = require('nvim-web-devicons').get_icons()
    for _, icon in pairs(devicons) do
      table.insert (
        hlgroups,
        {
          name = 'CokeDevIcon' .. icon.name .. 'Focused',
          guibg = hilights.buffers.focused.bg,
          guifg = icon.color,
        }
      )
      table.insert (
        hlgroups,
        {
          name = 'CokeDevIcon' .. icon.name .. 'Unfocused',
          guibg = hilights.buffers.unfocused.bg,
          guifg = icon.color,
        }
      )
    end
  end
  create_hlgroups(hlgroups)
end

return M
