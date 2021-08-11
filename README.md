# :nose: cokeline.nvim

This plugin is still under early development!

## Table of Contents

- [Features](#features)
  - [Customizable title formats](#customizable-title-formats)
  - [Separate styling for focused and unfocused buffers](#separate-styling-for-focused-and-unfocused-buffers)
  - [Clickable buffers](#clickable-buffers)
  - [Unique buffer names](#unique-buffer-names)
  - [Close icons](#close-icons)
  - [Buffer re-ordering](#buffer-re-ordering)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Mappings](#mappings)
- [TODO](#todo)
- [Credits](#credits)

## Features

TODO!

### Customizable title formats

### Separate styling for focused and unfocused buffers

### Clickable buffers

### Unique buffer names

### Close icons

### Buffer re-ordering

## Requirements

This plugin requires:

- neovim 0.5+;
- a patched font (see [Nerd Fonts](https://www.nerdfonts.com/)).

## Installation

If you ported your neovim config to Lua and use
[packer.nvim](https://github.com/wbthomason/packer.nvim) as your plugin
manager you can install this plugin with:

```lua
require('packer').startup(function()
  use {
    'noib3/cokeline.nvim',
    requires = 'kyazdani42/nvim-web-devicons', -- If you want devicons
  }
end)
```

Whereas if your config is still written in vimscript and use
[vim-plug](https://github.com/junegunn/vim-plug):

```vim
call plug#begin('~/.config/nvim/plugged')
  Plug 'kyazdani42/nvim-web-devicons' " If you want devicons
  Plug 'noib3/cokeline.nvim'
call plug#end()
```

## Usage

#### Lua

``` lua
vim.opt.termguicolors = true
require('cokeline').setup({})
```

#### Vimscript

``` vim
set termguicolors
lua << EOF
require('cokeline').setup({})
EOF
```

## Configuration

The following configuration options can be passed to the `setup` function to
customize both the behaviour and the look of the bufferline:

```lua
require('cokeline').setup({
  -- Whether the bufferline should be hidden when only one buffer is opened
  hide_when_one_buffer = false,

  -- The format of buffer titles. Available placeholders are:
  --    {devicon}: a colored icon of the filetype of the buffer (needs 'kyazdani42/nvim-web-devicons');
  --    {index}: ordinal index of the current buffer;
  --    {filename}: filename of the current buffer;
  --    {flags}: flags indicating if the buffer has been modified and if it is readonly;
  --    {close_button}: a clickable button to close the current buffer;
  line_format =  ' {index}: {filename}{flags} {close_button} ',

  -- The format of buffer flags
  flags_format = ' {flags}',

  -- A divider character displayed between the modified and readonly symbols
  -- (shown when both those flags are active).
  flags_divider = ',',

  -- Symbols used for the modified and readonly flags and for the buffer close
  -- button.
  symbols = {
    modified = '● ',
    readonly = '',
    close_button = '',
  },

  -- The default values for the following highlight groups are taken from the
  -- currently active colorscheme. Their values should be specified in
  -- hexadecimal format.
  highlights = {
    -- Used to fill the rest of the bufferline
    fill = '#rrggbb',

    -- Foreground and background colors of focused buffers
    focused_fg = '#rrggbb',
    focused_bg = '#rrggbb',

    -- Foreground and background colors of unfocused buffers
    unfocused_fg = '#rrggbb',
    unfocused_bg = '#rrggbb',

    -- Foreground colors of the unique part of a buffer name (shown when there
    -- are multiple buffers open with the same filename)
    unique_fg = '#rrggbb',

    -- Foreground colors of the modified and readonly symbols
    modified = '#rrggbb',
    readonly = '#rrggbb',
  },
})
```

More configuration options are likely to be added as the plugin matures and I
get feedback from other users.


## Mappings

The following `<Plug>` mappings are exposed to be able to focus buffers and to
switch their position. An example configuration could be:

``` vim
" Focus the previous/next buffer
nmap <silent> <Leader>k <Plug>(cokeline-focus-prev)
nmap <silent> <Leader>j <Plug>(cokeline-focus-next)

" Focus the n-th buffer
nmap <silent> <Leader>1 <Plug>(cokeline-focus-1)
nmap <silent> <Leader>2 <Plug>(cokeline-focus-2)
" …and so on

" Switch the position of the current buffer with the previous/next buffer
nmap <silent> <Leader>p <Plug>(cokeline-switch-prev)
nmap <silent> <Leader>n <Plug>(cokeline-switch-next)

" Switch the position of the current buffer with the n-th buffer
nmap <silent> <Space>1 <Plug>(cokeline-switch-1)
nmap <silent> <Space>2 <Plug>(cokeline-switch-2)
" …and so on
```

## TODO

Some of the features yet to be implemented include:

  - the ability to render the bufferline so as to keep the focused buffer
  always visible, even with a lot of buffers opened at the same time;

  - support for tabs;

  - support for sidebar offsets to provide a nice integration with
  NERDTree-like file explorer plugins;

  - customizable buffer separators (no separator characters are currently
  displayed);

  - equal sized buffer titles: if there are *n* buffers opened, every buffer
  title should take up *1/n* of the available space. This might be tricky to
  implement due to neovim being a terminal program and not a GUI one (i.e.,
  having to deal with discretely sized characters instead of pixels);

## Credits

The main inspiration for the aesthetics this plugin tries to replicate is the
way tabs are displayed in the
[qutebrowser](https://github.com/qutebrowser/qutebrowser) browser (have a look
at my [qutebrowser
config](https://github.com/noib3/dotfiles/blob/master/machines/blade/screenshots/qutebrowser.png)
for an example).

This being my first ever neovim plugin I also looked at how
[nvim-bufferline.lua](https://github.com/akinsho/nvim-bufferline.lua),
another great neovim bufferline, solved some issues that I stumbled into along
the way.

With that being said,
[nvim-bufferline.lua](https://github.com/akinsho/nvim-bufferline.lua) is a much
bigger project with a codebase roughly 5x bigger than the one of
[cokeline.nvim](https://github.com/noib3/cokeline.nvim), and while there are
some core features yet to be added (see [TODO](#todo)), the plan is to always
keep this plugin fairly small and minimal compared to other similar projects.
