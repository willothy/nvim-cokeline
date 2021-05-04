local has_devicons, _ = pcall(require, 'nvim-web-devicons')
local format = string.format
local vimcmd = vim.cmd
local vimfn = vim.fn
local M = {}

local tags = {
  'devicon',
  'index',
  'filename',
  'flags',
  'close_icon',
  'modified',
}
local placeholders = {}
for _, tag in pairs(tags) do
  placeholders[tag] = '{' .. tag .. '}'
end

local defaults = {
  -- behaviour
  hide_when_one_buffer = false,

  -- formatting
  formats = {
    title = format (
      '%s%s: %s%s %s',
      placeholders.devicon,
      placeholders.index,
      placeholders.filename,
      placeholders.flags,
      placeholders.close_icon
    ),
    flags = format(
      '[%s]',
      placeholders.modified
    ),
  },
  symbols = {
    close = '',
    modified = '+',
    separator = '',
  },

  -- colors & fonts
  hilights = {
    fill = {
      bg = '#3e4452',
    },
    buffers = {
      unfocused = {
        bg = '#3e4452',
        fg = '#abb2bf',
      },
      focused = {
        bg = '#abb2bf',
        fg = '#282c34',
      },
    },
    icons = {
      separator = {
        bg = '#3e4452',
        fg = '#abb2bf',
      },
    },
  }
}

function M.update(preferences)
  local settings = defaults
  local echoerr = function (msg)
    vimcmd(format(
      'echoerr "[cokeline.nvim]: %s"', msg))
  end

  for k, v in pairs(preferences) do
    if defaults[k] ~= nil then
      settings[k] = v
    else
      echoerr(format(
        'Configuration option "%s" does not exist!', k))
    end
  end

  settings['placeholders'] = placeholders

  settings['handle_clicks'] = vimfn.has('tablineat')

  settings['show_devicons'] =
    defaults.formats.title:match(placeholders.devicon)
    and has_devicons
    and true
    or false

  settings['show_close_icons'] =
    defaults.formats.title:match(placeholders.close_icon)
    and settings.handle_clicks
    and true
    or false

  return settings
end

return M
