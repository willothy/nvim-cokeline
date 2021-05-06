local format = string.format
local vimcmd = vim.cmd
local vimfn = vim.fn

local has_devicons, _ = pcall(require, 'nvim-web-devicons')

local M = {}

local title_components = {
  'devicon',
  'index',
  'filename',
  'flags',
  'close_button',
}

M.title_placeholders = {}
for _, component in pairs(title_components) do
  M.title_placeholders[component] = format('{%s}', component)
end

local defaults = {
  -- behaviour
  hide_when_one_buffer = false,

  -- formatting
  title_format = format(
    '%s%s: %s%s %s',
    M.title_placeholders.devicon,
    M.title_placeholders.index,
    M.title_placeholders.filename,
    M.title_placeholders.flags,
    M.title_placeholders.close_button
  ),

  symbols = {
    separator = '',
    close = '',
    flags = {
      modified = '+',
      readonly = 'RO',
    },
  },

  -- colors & fonts
  hilights = {
    fill = {
      bg = '#3e4452',
    },
    titles = {
      focused = {
        bg = '#abb2bf',
        fg = '#282c34',
      },
      unfocused = {
        bg = '#3e4452',
        fg = '#abb2bf',
      },
    },
    symbols = {
      separator = {
        bg = '#3e4452',
        fg = '#abb2bf',
      },
    },
  }
}

function M.merge(preferences)
  local settings = defaults
  local echoerr = function (msg)
    local fmt = 'echoerr "[cokeline.nvim]: %s"'
    vimcmd(fmt:format(msg))
  end

  for k, v in pairs(preferences) do
    if defaults[k] ~= nil then
      settings[k] = v
    else
      local msg = 'Configuration option "%s" does not exist!'
      echoerr(msg:format(k))
    end
  end

  settings['handle_clicks'] = vimfn.has('tablineat')

  settings['show_devicons'] =
    settings.title_format:match(M.title_placeholders.devicon)
    and has_devicons
    and true
     or false

  settings['show_indexes'] =
    settings.title_format:match(M.title_placeholders.index)
    and true
     or false

  settings['show_filenames'] =
    settings.title_format:match(M.title_placeholders.filename)
    and true
     or false

  settings['show_flags'] =
    settings.title_format:match(M.title_placeholders.flags)
    and true
     or false

  settings['show_close_buttons'] =
    settings.title_format:match(M.title_placeholders.close_button)
    and settings.handle_clicks
    and true
     or false

  return settings
end

return M
