local has_devicons, _ = pcall(require, 'nvim-web-devicons')

local format = string.format
local vimcmd = vim.cmd
local vimfn = vim.fn

local M = {}

local line_components = {
  'devicon',
  'index',
  'filename',
  'flags',
  'close_button',
}

M.line_placeholders = {}
for _, component in pairs(line_components) do
  M.line_placeholders[component] = format('{%s}', component)
end

local defaults = {
  hide_when_one_buffer = false,
  cycle_prev_next_mappings = false,
  max_mapped_buffers = 20,

  line_format = format(
    ' %s%s: %s%s %s ',
    M.line_placeholders.devicon,
    M.line_placeholders.index,
    M.line_placeholders.filename,
    M.line_placeholders.flags,
    M.line_placeholders.close_button
  ),

  flags_format = format(' %s', M.line_placeholders.flags),
  flags_divider = ',',

  symbols = {
    modified = '● ',
    readonly = '',
    close_button = '',
  },

  highlights = {
    fill = '#3e4452',
    focused_fg = '#282c34',
    focused_bg = '#abb2bf',
    unfocused_fg = '#abb2bf',
    unfocused_bg = '#3e4452',
    modified = '#98c379',
    readonly = '#e06c75',
  },
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
    settings.line_format:match(M.line_placeholders.devicon)
    and has_devicons
    and true
     or false

  settings['show_indexes'] =
    settings.line_format:match(M.line_placeholders.index)
    and true
     or false

  settings['show_filenames'] =
    settings.line_format:match(M.line_placeholders.filename)
    and true
     or false

  settings['show_flags'] =
    settings.line_format:match(M.line_placeholders.flags)
    and true
     or false

  settings['show_close_buttons'] =
    settings.line_format:match(M.line_placeholders.close_button)
    and settings.handle_clicks
    and true
     or false

  return settings
end

return M
