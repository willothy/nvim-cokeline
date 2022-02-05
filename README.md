<h1 align="center">
  &#128067; nvim-cokeline
</h1>

<p align="center">
<i>A Neovim bufferline for people with addictive personalities</i>
</p>

The goal of this plugin is not to be an opinionated bufferline with (more or
less) limited customization options. Rather, it tries to provide a general
framework allowing you to build ***your*** ideal bufferline, whatever that
might look like.

![preview](./.github/images/preview.png)


## :book: Table of Contents

- [Features](#sparkles-features)
- [Requirements](#electric_plug-requirements)
- [Installation](#package-installation)
- [Configuration](#wrench-configuration)
- [Mappings](#musical_keyboard-mappings)
- [Example configs](#nail_care-example-configs)


## :sparkles: Features

### Endlessly customizable

`nvim-cokeline` aims to be the most customizable bufferline plugin around. If
you have an idea in mind of what your bufferline should look like, you should
be able to make it look that way. If you can't, open an issue and we'll try to
make it happen!

Here's a (very limited) showcase of what it can be configured to look like
(check out [Example configs](#nail_care-showoff-of-user-configs) for more
examples):

<details>
<summary>Click to see configuration</summary>

```lua
local get_hex = require('cokeline/utils').get_hex

require('cokeline').setup({
  default_hl = {
    focused = {
      fg = get_hex('ColorColumn', 'bg'),
      bg = get_hex('Normal', 'fg'),
    },
    unfocused = {
      fg = get_hex('Normal', 'fg'),
      bg = get_hex('ColorColumn', 'bg'),
    },
  },

  components = {
    {
      text = function(buffer) return ' ' .. buffer.devicon.icon end,
      hl = {
        fg = function(buffer) return buffer.devicon.color end,
      },
    },
    {
      text = function(buffer) return buffer.unique_prefix end,
      hl = {
        fg = get_hex('Comment', 'fg'),
        style = 'italic',
      },
    },
    {
      text = function(buffer) return buffer.filename .. ' ' end,
    },
    {
      text = '',
      delete_buffer_on_left_click = true,
    },
    {
      text = ' ',
    }
  },
})
```
</details>

![cokeline-default](.github/images/cokeline-default.png)

<details>
<summary>Click to see configuration</summary>

```lua
local get_hex = require('cokeline/utils').get_hex

local green = vim.g.terminal_color_2
local yellow = vim.g.terminal_color_3

require('cokeline').setup({
  default_hl = {
    focused = {
      fg = get_hex('Normal', 'fg'),
      bg = get_hex('ColorColumn', 'bg'),
    },
    unfocused = {
      fg = get_hex('Comment', 'fg'),
      bg = get_hex('ColorColumn', 'bg'),
    },
  },

  components = {
    {
      text = '｜',
      hl = {
        fg = function(buffer)
          return
            buffer.is_modified and yellow or green
        end
      },
    },
    {
      text = function(buffer) return buffer.devicon.icon .. ' ' end,
      hl = {
        fg = function(buffer) return buffer.devicon.color end,
      },
    },
    {
      text = function(buffer) return buffer.index .. ': ' end,
    },
    {
      text = function(buffer) return buffer.unique_prefix end,
      hl = {
        fg = get_hex('Comment', 'fg'),
        style = 'italic',
      },
    },
    {
      text = function(buffer) return buffer.filename .. ' ' end,
      hl = {
        style = function(buffer) return buffer.is_focused and 'bold' or nil end,
      },
    },
    {
      text = ' ',
    },
  },
})
```
</details>

![cokeline-noib3](.github/images/cokeline-noib3.png)

<details>
<summary>Click to see configuration</summary>

```lua
local get_hex = require('cokeline/utils').get_hex

require('cokeline').setup({
  default_hl = {
    focused = {
      fg = get_hex('Normal', 'fg'),
      bg = 'NONE',
    },
    unfocused = {
      fg = get_hex('Comment', 'fg'),
      bg = 'NONE',
    },
  },

  components = {
    {
      text = function(buffer) return (buffer.index ~= 1) and '▏' or '' end,
      hl = {
        fg = get_hex('Normal', 'fg')
      },
    },
    {
      text = function(buffer) return '    ' .. buffer.devicon.icon end,
      hl = {
        fg = function(buffer) return buffer.devicon.color end,
      },
    },
    {
      text = function(buffer) return buffer.filename .. '    ' end,
      hl = {
        style = function(buffer) return buffer.is_focused and 'bold' or nil end,
      }
    },
    {
      text = '',
      delete_buffer_on_left_click = true,
    },
    {
      text = '  ',
    },
  },
})
```
</details>

![cokeline-bufferline](.github/images/cokeline-bufferline-lua.png)

### Dynamic rendering
<!-- ### Dynamic rendering (with sliders) -->

Even when you have a lot of buffers open, `nvim-cokeline` is rendered to always
keep the focused buffer visible and in the middle of the bufferline. Also, if a
buffer doesn't fit entirely we still try to include as much of it as possible
before cutting off the rest.

![rendering](./.github/images/rendering.gif)

### LSP support

If a buffer has an LSP client attached to it, you can configure the style of a
component to change based on how many errors, warnings, infos and hints are
reported by the LSP.

![lsp-styling](.github/images/lsp-styling.gif)

### Buffer pick

You can focus and close any buffer by typing its `pick_letter`. Letters are
assigned by filename by default (e.g. `foo.txt` gets the letter `f`), and by
keyboard reachability if the letter is already assigned to another buffer.

<details>
<summary>Click to see configuration</summary>

```lua
local is_picking_focus = require('cokeline/mappings').is_picking_focus
local is_picking_close = require('cokeline/mappings').is_picking_close
local get_hex = require('cokeline/utils').get_hex

local red = vim.g.terminal_color_1
local yellow = vim.g.terminal_color_3

require('cokeline').setup({
  default_hl = {
    focused = {
      fg = get_hex('Normal', 'fg'),
      bg = get_hex('ColorColumn', 'bg'),
    },
    unfocused = {
      fg = get_hex('Comment', 'fg'),
      bg = get_hex('ColorColumn', 'bg'),
    },
  },

  components = {
    {
      text = function(buffer) return (buffer.index ~= 1) and '▏' or '' end,
    },
    {
      text = '  ',
    },
    {
      text = function(buffer)
        return
          (is_picking_focus() or is_picking_close())
          and buffer.pick_letter .. ' '
           or buffer.devicon.icon
      end,
      hl = {
        fg = function(buffer)
          return
            (is_picking_focus() and yellow)
            or (is_picking_close() and red)
            or buffer.devicon.color
        end,
        style = function(_)
          return
            (is_picking_focus() or is_picking_close())
            and 'italic,bold'
             or nil
        end,
      },
    },
    {
      text = ' ',
    },
    {
      text = function(buffer) return buffer.filename .. '  ' end,
      hl = {
        style = function(buffer) return buffer.is_focused and 'bold' or nil end,
      }
    },
    {
      text = '',
      delete_buffer_on_left_click = true,
    },
    {
      text = '  ',
    },
  },
})
```
</details>

![buffer-pick](.github/images/buffer-pick.gif)

### Sidebars

You can add left and right sidebars to integrate nicely with file explorer
plugins like
[nvim-tree.lua](https://github.com/kyazdani42/nvim-tree.lua),
[CHADTree](https://github.com/ms-jpq/chadtree) or
[NERDTree](https://github.com/preservim/nerdtree).

<details>
<summary>Click to see configuration</summary>

```lua
local get_hex = require('cokeline/utils').get_hex

local yellow = vim.g.terminal_color_3

require('cokeline').setup({
  default_hl = {
    focused = {
      fg = get_hex('Normal', 'fg'),
      bg = get_hex('ColorColumn', 'bg'),
    },
    unfocused = {
      fg = get_hex('Comment', 'fg'),
      bg = get_hex('ColorColumn', 'bg'),
    },
  },

  rendering = {
    left_sidebar = {
      filetype = 'NvimTree',
      components = {
        {
          text = '  NvimTree',
          hl = {
            fg = yellow,
            bg = get_hex('NvimTreeNormal', 'bg'),
            style = 'bold'
          }
        },
      }
    },
  },

  components = {
    {
      text = function(buffer) return (buffer.index ~= 1) and '▏' or '' end,
    },
    {
      text = '  ',
    },
    {
      text = function(buffer)
        return buffer.devicon.icon
      end,
      hl = {
        fg = function(buffer)
          return buffer.devicon.color
        end,
      },
    },
    {
      text = ' ',
    },
    {
      text = function(buffer) return buffer.filename .. '  ' end,
      hl = {
        style = function(buffer)
          return buffer.is_focused and 'bold' or nil
        end,
      }
    },
    {
      text = '',
      delete_buffer_on_left_click = true,
    },
    {
      text = '  ',
    },
  },
})
```
</details>

![sidebars](.github/images/sidebars.png)

### Unique buffer names

When files with the same filename belonging to different directories are opened
simultaneously, you can include a unique filetree prefix to distinguish between
them:

![unique-prefix](.github/images/unique-prefix.gif)

### Clickable buffers

You can switch focus between buffers with a left click and you can delete
them with a right click:

![clickable-buffers](.github/images/clickable-buffers.gif)

### Buffer re-ordering

![reordering](.github/images/reordering.gif)

### Close icons

![close-icons](.github/images/close-icons.gif)


## :electric_plug: Requirements

The two main requirements are Neovim 0.5+ and the `termguicolors` option to be
set. If you want to display devicons in your bufferline you'll also need the
[kyazdani42/nvim-web-devicons](https://github.com/kyazdani42/nvim-web-devicons)
plugin and a patched font (see [Nerd Fonts](https://www.nerdfonts.com/)).


## :package: Installation

#### Lua

If you ported your Neovim config to Lua and use
[packer.nvim](https://github.com/wbthomason/packer.nvim) as your plugin
manager you can install this plugin with:
```lua
vim.opt.termguicolors = true

require('packer').startup(function()
  -- ...
  use({
    'noib3/nvim-cokeline',
    requires = 'kyazdani42/nvim-web-devicons', -- If you want devicons
    config = function()
      require('cokeline').setup()
    end
  })
  -- ...
end)
```

#### Vimscript

If your config is still written in Vimscript and you use
[vim-plug](https://github.com/junegunn/vim-plug):
```vim
call plug#begin('~/.config/nvim/plugged')
  " ...
  Plug 'kyazdani42/nvim-web-devicons' " If you want devicons
  Plug 'noib3/nvim-cokeline'
  " ...
call plug#end()

set termguicolors
lua << EOF
  require('cokeline').setup()
EOF
```


## :wrench: Configuration

All the configuration is done by changing the contents of the Lua table passed to
the `setup` function.

The valid keys are:
```lua
require('cokeline').setup({
  -- Only show the bufferline when there are at least this many visible buffers.
  -- default: `1`.
  show_if_buffers_are_at_least = int,

  buffers = {
    -- A function to filter out unwanted buffers. Takes a buffer table as a
    -- parameter (see the following section for more infos) and has to return
    -- either `true` or `false`.
    -- default: `false`.
    filter_valid = function(buffer) -> true | false,

    -- A looser version of `filter_valid`, use this function if you still
    -- want the `cokeline-{switch,focus}-{prev,next}` mappings to work for
    -- these buffers without displaying them in your bufferline.
    -- default: `false`.
    filter_visible = function(buffer) -> true | false,

    -- Which buffer to focus when a buffer is deleted, `prev` focuses the
    -- buffer to the left of the deleted one while `next` focuses the one the
    -- right. Turned off by default.
    -- default: `false`
    focus_on_delete = 'prev' | 'next',

    -- If set to `last` new buffers are added to the end of the bufferline,
    -- if `next` they are added next to the current buffer.
    -- default: 'last',
    new_buffers_position = 'last' | 'next',
  },

  mappings = {
    -- Controls what happens when the first (last) buffer is focused and you
    -- try to focus/switch the previous (next) buffer. If `true` the last
    -- (first) buffers gets focused/switched, if `false` nothing happens.
    -- default: `true`.
    cycle_prev_next = true | false,
  },

  rendering = {
    -- The maximum number of characters a rendered buffer is allowed to take
    -- up. The buffer will be truncated if its width is bigger than this
    -- value.
    -- default: `999`.
    max_buffer_width = int,

    -- Left and right sidebars to integrate nicely with file explorer plugins.
    -- Each of these is a table containing a `filetype` key and a list of
    -- `components` to be rendered in the sidebar.
    -- The last component will be automatically space padded if necessary
    -- to ensure the sidebar and the window below it have the same width.
    -- NOTE: unlike the `components` config option described below, right now
    -- these components don't allow any of their fields (text, hl, etc.) to be
    -- defined as a function of `buffer`.
    left_sidebar = {
      filetype = '<filetype>',
      components = {..},
    },
    right_sidebar = {
      filetype = '<filetype>',
      components = {..},
    },
  },

  -- The default highlight group values for focused and unfocused buffers.
  -- The `fg` and `bg` keys are either colors in hexadecimal format or
  -- functions taking a `buffer` parameter and returning a color in
  -- hexadecimal format. Similarly, the `style` key is either a string
  -- containing a comma separated list of items in `:h attr-list` or a
  -- function returning one.
  default_hl = {
    focused = {
      -- default: `ColorColumn`'s background color.
      fg = '#rrggbb' | function(buffer) -> '#rrggbb',

      -- default: `Normal`'s foreground color.
      bg = '#rrggbb' | function(buffer) -> '#rrggbb',

      -- default: `'NONE'`.
      style = 'attr1,attr2,...' | function(buffer) -> 'attr1,attr2,...',
    },

    unfocused = {
      -- default: `Normal`'s foreground color.
      fg = '#rrggbb' | function(buffer) -> '#rrggbb',

      -- default: `ColorColumn`'s background color.
      bg = '#rrggbb' | function(buffer) -> '#rrggbb',

      -- default: `'NONE'`.
      style = 'attr1,attr2,...' | function(buffer) -> 'attr1,attr2,...',
    },
  },

  -- A list of components to be rendered for each buffer. Check out the section
  -- below explaining what this value can be set to.
  -- default: see `/lua/cokeline/defaults.lua`
  components = {..},
})
```

#### So what's `function(buffer)`?

Some of the configuration options can be functions that take a `buffer` as a
single parameter. This is useful as it allows users to set the values of
components dynamically based on the buffer that component is being rendered
for.

The `buffer` parameter is just a Lua table with the following keys:
```lua
buffer = {
  -- The buffer's order in the bufferline (1 for the first buffer, 2 for the
  -- second one, etc.).
  index = int,

  -- The buffer's internal number as reported by `:ls`.
  number = int,

  is_focused = true | false,

  is_modified = true | false,

  is_readonly = true | false,

  -- The buffer's type as reported by `:echo &buftype`.
  type = 'string',

  -- The buffer's filetype as reported by `:echo &filetype`.
  filetype = 'string',

  -- The buffer's full path.
  path = 'string',

  -- The buffer's filename.
  filename = 'string',

  -- A unique prefix used to distinguish buffers with the same filename
  -- stored in different directories. For example, if we have two files
  -- `bar/foo.md` and `baz/foo.md`, then the first will have `bar/` as its
  -- unique prefix and the second one will have `baz/`.
  unique_prefix = 'string',

  -- The letter that is displayed when picking a buffer to either focus or
  -- close it.
  pick_letter = 'char',

  -- This needs the `kyazdani42/nvim-web-devicons` plugin to be installed.
  devicon = {
    -- An icon representing the buffer's filetype.
    icon = 'string',

    -- The colors of the devicon in hexadecimal format (useful to be passed
    -- to a component's `hl.fg` field (see the `Components` section).
    color = '#rrggbb',
  },

  -- The values in this table are the ones reported by Neovim's built in
  -- LSP interface.
  diagnostics = {
    errors = int,
    warnings = int,
    infos = int,
    hints = int,
  },
}
```

#### What about `components`?

You can configure what each buffer in your bufferline will be composed of by
passing a list of components to the `setup` function.

For example, let's imagine we want to construct a very minimal bufferline
where the only things we're displaying for each buffer are its index, its
filename and a close button.

Then in our `setup` function we'd have:
```lua
require('cokeline').setup({
  -- ...

  components = {
    {
      text = function(buffer) return ' ' .. buffer.index end,
    },
    {
      text = function(buffer) return ' ' .. buffer.filename .. ' ' end,
    },
    {
      text = '',
      delete_buffer_on_left_click = true,
    },
    {
      text = ' ',
    }
  }
}
```
in this case every buffer would be composed of four components: the first
displaying a space followed by the buffer index, the second one the filename
padded by a space on each side, then a close button that allows us to
`:bdelete` the buffer by left-clicking on it, and finally an extra space.

This way of dividing each buffer into distinct components, combined with the
ability to define every component's text and color depending on some property
of the buffer we're rendering, allows for great customizability.

Every component passed to the `components` list has to be a table of the form:
```lua
{
  text = 'string' | function(buffer) -> 'string',

  -- The foreground, backgrond and style of the component. `style` is a
  -- comma-separated string of values defined in `:h attr-list`.
  hl = {
    fg = '#rrggbb' | function(buffer) -> '#rrggbb',
    bg = '#rrggbb' | function(buffer) -> '#rrggbb',
    style = 'attr1,attr2,...' | function(buffer) -> 'attr1,attr2,...',
  },

  -- If `true` the buffer will be deleted when this component is
  -- left-clicked (useful to implement close buttons).
  delete_buffer_on_left_click = true | false,

  truncation = {
    -- default: index of the component in the `components` table (1 for the
    -- first component, 2 for the second, etc.).
    priority = int,

    -- default: `right`.
    direction = 'left' | 'middle' | 'right',
  },
}
```
the `text` key is the only one that has to be set, all the others are optional
and can be omitted.

The `truncation` table controls what happens when a buffer is too long to be
displayed in its entirety.

More specifically, if a buffer's width (given by the sum of the widths of all
its components) is bigger than the `rendering.max_buffer_width` config option,
the buffer will be truncated.

The default behaviour is truncate the buffer by dropping components from right
to left, with the text of the last component that's included also being
shortened from right to left. This can be modified by changing the values of
the `truncation.priority` and `truncation.direction` keys.

The `truncation.priority` controls the order in which components are dropped:
the first component to be dropped will be the one with the lowest priority. If
that's still not enough to bring the width of the buffer within the
`rendering.max_buffer_width` limit, the component with the second lowest
priority will be dropped, and so on. Note that a higher priority means a
smaller integer value: a component with a priority of 5 will be dropped
*after* a component with a priority of 6, even though 6 > 5.

The `truncation.direction` key simply controls from which direction a component
is shortened. For example, you might want to set the `truncation.direction` of
a component displaying a filename to `'middle'` or `'left'`, so that if
the filename has to be shortened you'll still be able to see its extension,
like in the following example (where it's set to `'left'`):

![buffer-truncation](.github/images/buffer-truncation.png)

## :musical_keyboard: Mappings

We expose the following `<Plug>` mappings which can be used as the right hand
side of other mappings:

```lua
-- Focus the previous/next buffer
<Plug>(cokeline-focus-prev)
<Plug>(cokeline-focus-next)

-- Switch the position of the current buffer with the previous/next buffer.
<Plug>(cokeline-switch-prev)
<Plug>(cokeline-switch-next)

-- Focuses the buffer with index `i`.
<Plug>(cokeline-focus-i)

-- Switches the position of the current buffer with the buffer of index `i`.
<Plug>(cokeline-switch-i)

-- Focus a buffer by its `pick_letter`.
<Plug>(cokeline-pick-focus)

-- Close a buffer by its `pick_letter`.
<Plug>(cokeline-pick-close)
```

A possible configuration could be:

```lua
local map = vim.api.nvim_set_keymap

map('n', '<S-Tab>',   '<Plug>(cokeline-focus-prev)',  { silent = true })
map('n', '<Tab>',     '<Plug>(cokeline-focus-next)',  { silent = true })
map('n', '<Leader>p', '<Plug>(cokeline-switch-prev)', { silent = true })
map('n', '<Leader>n', '<Plug>(cokeline-switch-next)', { silent = true })

for i = 1,9 do
  map('n', ('<F%s>'):format(i),      ('<Plug>(cokeline-focus-%s)'):format(i),  { silent = true })
  map('n', ('<Leader>%s'):format(i), ('<Plug>(cokeline-switch-%s)'):format(i), { silent = true })
end
```


## :nail_care: Example configs

Open a new issue or send a PR if you'd like to have your configuration featured
here!

### author: [@noib3](https://github.com/noib3/dotfiles)

<details>
<summary>Click to see configuration</summary>

```lua
local get_hex = require('cokeline/utils').get_hex
local mappings = require('cokeline/mappings')

local comments_fg = get_hex('Comment', 'fg')
local errors_fg = get_hex('DiagnosticError', 'fg')
local warnings_fg = get_hex('DiagnosticWarn', 'fg')

local red = vim.g.terminal_color_1
local yellow = vim.g.terminal_color_3

local components = {
  space = {
    text = ' ',
    truncation = { priority = 1 }
  },

  two_spaces = {
    text = '  ',
    truncation = { priority = 1 },
  },

  separator = {
    text = function(buffer)
      return buffer.index ~= 1 and '▏' or ''
    end,
    truncation = { priority = 1 }
  },

  devicon = {
    text = function(buffer)
      return
        (mappings.is_picking_focus() or mappings.is_picking_close())
          and buffer.pick_letter .. ' '
           or buffer.devicon.icon
    end,
    hl = {
      fg = function(buffer)
        return
          (mappings.is_picking_focus() and yellow)
          or (mappings.is_picking_close() and red)
          or buffer.devicon.color
      end,
      style = function(_)
        return
          (mappings.is_picking_focus() or mappings.is_picking_close())
          and 'italic,bold'
           or nil
      end,
    },
    truncation = { priority = 1 }
  },

  index = {
    text = function(buffer)
      return buffer.index .. ': '
    end,
    truncation = { priority = 1 }
  },

  unique_prefix = {
    text = function(buffer)
      return buffer.unique_prefix
    end,
    hl = {
      fg = comments_fg,
      style = 'italic',
    },
    truncation = {
      priority = 3,
      direction = 'left',
    },
  },

  filename = {
    text = function(buffer)
      return buffer.filename
    end,
    hl = {
      style = function(buffer)
        return
          ((buffer.is_focused and buffer.diagnostics.errors ~= 0)
            and 'bold,underline')
          or (buffer.is_focused and 'bold')
          or (buffer.diagnostics.errors ~= 0 and 'underline')
          or nil
      end
    },
    truncation = {
      priority = 2,
      direction = 'left',
    },
  },

  diagnostics = {
    text = function(buffer)
      return
        (buffer.diagnostics.errors ~= 0 and '  ' .. buffer.diagnostics.errors)
        or (buffer.diagnostics.warnings ~= 0 and '  ' .. buffer.diagnostics.warnings)
        or ''
    end,
    hl = {
      fg = function(buffer)
        return
          (buffer.diagnostics.errors ~= 0 and errors_fg)
          or (buffer.diagnostics.warnings ~= 0 and warnings_fg)
          or nil
      end,
    },
    truncation = { priority = 1 },
  },

  close_or_unsaved = {
    text = function(buffer)
      return buffer.is_modified and '●' or ''
    end,
    hl = {
      fg = function(buffer)
        return buffer.is_modified and green or nil
      end
    },
    delete_buffer_on_left_click = true,
    truncation = { priority = 1 },
  },
}

require('cokeline').setup({
  show_if_buffers_are_at_least = 2,

  buffers = {
    -- filter_valid = function(buffer) return buffer.type ~= 'terminal' end,
    -- filter_visible = function(buffer) return buffer.type ~= 'terminal' end,
    new_buffers_position = 'next',
  },

  rendering = {
    max_buffer_width = 30,
  },

  default_hl = {
    focused = {
      fg = get_hex('Normal', 'fg'),
      bg = get_hex('ColorColumn', 'bg'),
    },
    unfocused = {
      fg = get_hex('Comment', 'fg'),
      bg = get_hex('ColorColumn', 'bg'),
    },
  },

  components = {
    components.space,
    components.separator,
    components.space,
    components.devicon,
    components.space,
    components.index,
    components.unique_prefix,
    components.filename,
    components.diagnostics,
    components.two_spaces,
    components.close_or_unsaved,
    components.space,
  },
})
```
</details>

![userconfig-noib3](.github/images/preview.png)

<details>
<summary>This config shows how you configure buffers w/ rounded corners.</summary>

```lua
local get_hex = require('cokeline/utils').get_hex

require('cokeline').setup({
  default_hl = {
    focused = {
      fg = get_hex('Normal', 'fg'),
      bg = get_hex('ColorColumn', 'bg'),
    },
    unfocused = {
      fg = get_hex('Comment', 'fg'),
      bg = get_hex('ColorColumn', 'bg'),
    },
  },

  components = {
    {
      text = ' ',
      hl = {
        bg = get_hex('Normal', 'bg'),
      },
    },
    {
      text = '',
      hl = {
        fg = get_hex('ColorColumn', 'bg'),
        bg = get_hex('Normal', 'bg'),
      },
    },
    {
      text = function(buffer)
        return buffer.devicon.icon
      end,
      hl = {
        fg = function(buffer)
          return buffer.devicon.color
        end,
      },
    },
    {
      text = ' ',
    },
    {
      text = function(buffer) return buffer.filename .. '  ' end,
      hl = {
        style = function(buffer)
          return buffer.is_focused and 'bold' or nil
        end,
      }
    },
    {
      text = '',
      delete_buffer_on_left_click = true,
    },
    {
      text = '',
      hl = {
        fg = get_hex('ColorColumn', 'bg'),
        bg = get_hex('Normal', 'bg'),
      },
    },
  },
})
```
</details>

![userconfig-noib3](.github/images/buffer-separators.png)

<details>
<summary>
This config shows how to get equally sized buffers. All the buffers
are 23 characters wide, adding padding spaces left and right if a buffer is too
short and cutting it off if it's too long.
</summary>

```lua
local get_hex = require('cokeline/utils').get_hex
local mappings = require('cokeline/mappings')

local str_rep = string.rep

local green = vim.g.terminal_color_2
local yellow = vim.g.terminal_color_3

local comments_fg = get_hex('Comment', 'fg')
local errors_fg = get_hex('DiagnosticError', 'fg')
local warnings_fg = get_hex('DiagnosticWarn', 'fg')

local min_buffer_width = 23

local components = {
  separator = {
    text = ' ',
    hl = { bg = get_hex('Normal', 'bg') },
    truncation = { priority = 1 },
  },

  space = {
    text = ' ',
    truncation = { priority = 1 },
  },

  left_half_circle = {
    text = '',
    hl = {
      fg = get_hex('ColorColumn', 'bg'),
      bg = get_hex('Normal', 'bg'),
    },
    truncation = { priority = 1 },
  },

  right_half_circle = {
    text = '',
    hl = {
      fg = get_hex('ColorColumn', 'bg'),
      bg = get_hex('Normal', 'bg'),
    },
    truncation = { priority = 1 },
  },

  devicon = {
    text = function(buffer)
      return buffer.devicon.icon
    end,
    hl = {
      fg = function(buffer)
        return buffer.devicon.color
      end,
      end,
    },
    truncation = { priority = 1 },
  },

  index = {
    text = function(buffer)
      return buffer.index .. ': '
    end,
    hl = {
      fg = function(buffer)
        return
          (buffer.diagnostics.errors ~= 0 and errors_fg)
          or (buffer.diagnostics.warnings ~= 0 and warnings_fg)
          or nil
      end,
    },
    truncation = { priority = 1 },
  },

  unique_prefix = {
    text = function(buffer)
      return buffer.unique_prefix
    end,
    hl = {
      fg = comments_fg,
      style = 'italic',
    },
    truncation = {
      priority = 3,
      direction = 'left',
    },
  },

  filename = {
    text = function(buffer)
      return buffer.filename
    end,
    hl = {
      fg = function(buffer)
        return
          (buffer.diagnostics.errors ~= 0 and errors_fg)
          or (buffer.diagnostics.warnings ~= 0 and warnings_fg)
          or nil
      end,
      style = function(buffer)
        return
          ((buffer.is_focused and buffer.diagnostics.errors ~= 0)
            and 'bold,underline')
          or (buffer.is_focused and 'bold')
          or (buffer.diagnostics.errors ~= 0 and 'underline')
          or nil
      end
    },
    truncation = {
      priority = 2,
      direction = 'left',
    },
  },

  close_or_unsaved = {
    text = function(buffer)
      return buffer.is_modified and '●' or ''
    end,
    hl = {
      fg = function(buffer)
        return buffer.is_modified and green or nil
      end
    },
    delete_buffer_on_left_click = true,
    truncation = { priority = 1 },
  },
}

local get_remaining_space = function(buffer)
  local used_space = 0
  for _, component in pairs(components) do
    used_space = used_space + vim.fn.strwidth(
      (type(component.text) == 'string' and component.text)
      or (type(component.text) == 'function' and component.text(buffer))
    )
  end
  return math.max(0, min_buffer_width - used_space)
end

local left_padding = {
  text = function(buffer)
    local remaining_space = get_remaining_space(buffer)
    return str_rep(' ', remaining_space / 2 + remaining_space % 2)
  end,
}

local right_padding = {
  text = function(buffer)
    local remaining_space = get_remaining_space(buffer)
    return str_rep(' ', remaining_space / 2)
  end,
}

require('cokeline').setup({
  show_if_buffers_are_at_least = 2,

  buffers = {
    -- filter_valid = function(buffer) return buffer.type ~= 'terminal' end,
    -- filter_visible = function(buffer) return buffer.type ~= 'terminal' end,
    focus_on_delete = 'next',
    new_buffers_position = 'next',
  },

  rendering = {
    max_buffer_width = 23,
    left_sidebar = {
      filetype = 'NvimTree',
      components = {
        {
          text = '  NvimTree',
          hl = {
            fg = yellow,
            bg = get_hex('NvimTreeNormal', 'bg'),
            style = 'bold'
          }
        },
      }
    },
  },

  default_hl = {
    focused = {
      fg = get_hex('Normal', 'fg'),
      bg = get_hex('ColorColumn', 'bg'),
    },
    unfocused = {
      fg = get_hex('Comment', 'fg'),
      bg = get_hex('ColorColumn', 'bg'),
    },
  },

  components = {
    components.separator,
    components.left_half_circle,
    left_padding,
    components.devicon,
    components.index,
    components.unique_prefix,
    components.filename,
    components.space,
    right_padding,
    components.close_or_unsaved,
    components.right_half_circle,
  },
})

```
</details>

![userconfig-noib3](.github/images/equally-sized-buffers.png)

### author: [@olimorris](https://github.com/olimorris/dotfiles)

<details>
<summary>Click to see configuration</summary>

```lua
local M = {}

function M.setup()
  local present, cokeline = pcall(require, "cokeline")
  if not present then
    return
  end

  local colors = require("colors").get()

  cokeline.setup({

    show_if_buffers_are_at_least = 2,

    mappings = {
      cycle_prev_next = true,
    },

    default_hl = {
      focused = {
        fg = colors.purple,
        bg = "NONE",
        style = "bold",
      },
      unfocused = {
        fg = colors.gray,
        bg = "NONE",
      },
    },

    components = {
      {
        text = function(buffer)
          return buffer.index ~= 1 and "  "
        end,
      },
      {
        text = function(buffer)
          return buffer.index .. ": "
        end,
        hl = {
          style = function(buffer)
            return buffer.is_focused and "bold" or nil
          end,
        },
      },
      {
        text = function(buffer)
          return buffer.unique_prefix
        end,
        hl = {
          fg = function(buffer)
            return buffer.is_focused and colors.purple or colors.gray
          end,
          style = "italic",
        },
      },
      {
        text = function(buffer)
          return buffer.filename .. " "
        end,
        hl = {
          style = function(buffer)
            return buffer.is_focused and "bold" or nil
          end,
        },
      },
      {
        text = function(buffer)
          return buffer.is_modified and " ●"
        end,
        hl = {
          fg = function(buffer)
            return buffer.is_focused and colors.red
          end,
        },
      },
      {
        text = "  ",
      },
    },
  })
end

return M
```
</details>

![userconfig-olimorris](.github/images/userconfig-olimorris.gif)


### author: [@alex-popov-tech](https://github.com/alex-popov-tech/.dotfiles)

<details>
<summary>Click to see configuration</summary>

```lua
return function()
    local get_hex = require("cokeline/utils").get_hex
    local space = {text = " "}
    require("cokeline").setup(
        {
            mappings = {
              cycle_prev_next = true,
            },
            default_hl = {
                focused = {
                    bg = "none"
                },
                unfocused = {
                    fg = get_hex("Comment", "fg"),
                    bg = "none"
                }
            },
            components = {
                space,
                {
                    text = function(buffer)
                        return buffer.devicon.icon
                    end,
                    hl = {
                        fg = function(buffer)
                            return buffer.devicon.color
                        end
                    }
                },
                {
                    text = function(buffer)
                        return buffer.filename
                    end,
                    hl = {
                        fg = function(buffer)
                            if buffer.is_focused then
                                return "#78dce8"
                            end
                            if buffer.is_modified then
                                return "#e5c463"
                            end
                            if buffer.lsp.errors ~= 0 then
                                return "#fc5d7c"
                            end
                        end,
                        style = function(buffer)
                            if buffer.is_focused then
                                return "underline"
                            end
                            return nil
                        end
                    }
                },
                {
                    text = function(buffer)
                        if buffer.is_readonly then
                            return " 🔒"
                        end
                        return ""
                    end
                },
                space
            }
        }
    )
end
```
</details>

![userconfig-alex-popov-tech](.github/images/userconfig-alex-popov-tech.png)
