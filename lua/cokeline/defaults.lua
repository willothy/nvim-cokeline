local get_hex = require('cokeline/hlgroups').get_hex

local has_devicons, _ = pcall(require, 'nvim-web-devicons')

local format = string.format

local fn = vim.fn
local g = vim.g

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
  mouse_close_command = 'bdelete',

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
    fill = get_hex('ColorColumn', 'bg'),
    focused_fg = get_hex('ColorColumn', 'bg'),
    focused_bg = get_hex('Normal', 'fg'),
    unfocused_fg = get_hex('Normal', 'fg'),
    unfocused_bg = get_hex('Visual', 'bg'),
    modified = get_hex('String', 'fg'),
    readonly = get_hex('Error', 'fg'),
  },
}

function M.merge(preferences)
  local settings = defaults
  local echoerr = function(msg)
    local fmt = '[cokeline.nvim]: %s'
    vim.api.nvim_echo({{fmt:format(msg), 'ErrorMsg'}}, true, {})
  end

  for k, v in pairs(preferences) do
    if defaults[k] ~= nil then
      settings[k] = v
    else
      local msg = 'Configuration option "%s" does not exist!'
      echoerr(msg:format(k))
    end
  end

  settings['handle_clicks'] = fn.has('tablineat')

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

  if settings.handle_clicks then
    g.cokeline_mouse_close_command = settings.mouse_close_command
  end

  return settings
end

return M
