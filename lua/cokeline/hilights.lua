local has_devicons, devicons = pcall(require, 'nvim-web-devicons')
local vimcmd = vim.cmd
local format = string.format
local M = {}

local function create_hlgroups(hlgroups)
  local cmd
  for _, hlgroup in pairs(hlgroups) do
    cmd = 'highlight! ' .. hlgroup.name
    for k, v in pairs(hlgroup) do
      if k ~= 'name' then
        cmd = format('%s %s=%s', cmd, k, v)
      end
    end
    vimcmd(cmd)
  end
end

function M.setup(settings)
  local hilights = settings.highlights
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
  if has_devicons and settings.use_devicons then
    for _, icon in pairs(devicons.get_icons()) do
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
