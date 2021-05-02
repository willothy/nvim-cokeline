local defaults = {
  use_devicons = false,
  hide_when_one_buffer = false,
  title_format = '{icon}{index}: {name} {flags}',
  highlights = {
    cokeline = {bg='#3e4452'},
    buffers = {
      unfocused = {bg='#3e4452', fg='#abb2bf'},
      focused = {bg='#abb2bf', fg = '#282c34'},
    }
  }
}

return defaults
