<!-- panvimdoc-include-comment <br> -->
<h1 align="center">
  &#128067; nvim-cokeline
</h1>
<!-- panvimdoc-include-comment <br> -->

<p align="center">
<i>A Neovim bufferline for people with addictive personalities</i>
</p>
<!-- panvimdoc-include-comment <br> -->

The goal of this plugin is not to be an opinionated bufferline with (more or
less) limited customization options. Rather, it tries to provide a general
framework allowing you to build **_your_** ideal bufferline, whatever that
might look like.

<!-- panvimdoc-ignore-start -->
![preview](https://user-images.githubusercontent.com/38540736/226447816-c696153f-ccee-4e4a-8b6a-55e53ee737f8.png)

## :book: Table of Contents

- [Features](#sparkles-features)
- [Requirements](#electric_plug-requirements)
- [Installation](#package-installation)
- [Configuration](#wrench-configuration)
- [Mappings](#musical_keyboard-mappings)

<!-- panvimdoc-ignore-end -->

## :sparkles: Features

### Endlessly customizable

`nvim-cokeline` aims to be the most customizable bufferline plugin around. If
you have an idea in mind of what your bufferline should look like, you should
be able to make it look that way. If you can't, open an issue and we'll try to
make it happen!

<!-- panvimdoc-ignore-start -->
Here's a (very limited) showcase of what it can be configured to look like
(check out the wiki for more examples):

<details>
<summary>Click to see configuration</summary>

```lua
local get_hex = require('cokeline.hlgroups').get_hl_attr

require('cokeline').setup({
  default_hl = {
    fg = function(buffer)
      return
        buffer.is_focused
        and get_hex('ColorColumn', 'bg')
         or get_hex('Normal', 'fg')
    end,
    bg = function(buffer)
      return
        buffer.is_focused
        and get_hex('Normal', 'fg')
         or get_hex('ColorColumn', 'bg')
    end,
  },

  components = {
    {
      text = function(buffer) return ' ' .. buffer.devicon.icon end,
      fg = function(buffer) return buffer.devicon.color end,
    },
    {
      text = function(buffer) return buffer.unique_prefix end,
      fg = get_hex('Comment', 'fg'),
      italic = true
    },
    {
      text = function(buffer) return buffer.filename .. ' ' end,
      underline = function(buffer)
        return buffer.is_hovered and not buffer.is_focused
      end
    },
    {
      text = '',
      on_click = function(_, _, _, _, buffer)
        buffer:delete()
      end
    },
    {
      text = ' ',
    }
  },
})
```

</details>

![cokeline-default](https://user-images.githubusercontent.com/38540736/226447806-0d4be251-788e-495c-abf7-ae5041dcc702.png)

<details>
<summary>Click to see configuration</summary>

```lua
local get_hex = require('cokeline.hlgroups').get_hl_attr

local green = vim.g.terminal_color_2
local yellow = vim.g.terminal_color_3

require('cokeline').setup({
  default_hl = {
    fg = function(buffer)
      return
        buffer.is_focused
        and get_hex('Normal', 'fg')
         or get_hex('Comment', 'fg')
    end,
    bg = get_hex('ColorColumn', 'bg'),
  },

  components = {
    {
      text = '｜',
      fg = function(buffer)
        return
          buffer.is_modified and yellow or green
      end
    },
    {
      text = function(buffer) return buffer.devicon.icon .. ' ' end,
      fg = function(buffer) return buffer.devicon.color end,
    },
    {
      text = function(buffer) return buffer.index .. ': ' end,
    },
    {
      text = function(buffer) return buffer.unique_prefix end,
      fg = get_hex('Comment', 'fg'),
      italic = true,
    },
    {
      text = function(buffer) return buffer.filename .. ' ' end,
      bold = function(buffer) return buffer.is_focused end,
    },
    {
      text = ' ',
    },
  },
})
```

</details>

![cokeline-noib3](https://user-images.githubusercontent.com/38540736/226447808-fc834732-efd1-4fd1-a0de-65ebea213d3f.png)

<details>
<summary>Click to see configuration</summary>

```lua
local get_hex = require('cokeline.hlgroups').get_hl_attr

require('cokeline').setup({
  default_hl = {
    fg = function(buffer)
      return
        buffer.is_focused
        and get_hex('Normal', 'fg')
         or get_hex('Comment', 'fg')
    end,
    bg = 'NONE',
  },
  components = {
    {
      text = function(buffer) return (buffer.index ~= 1) and '▏' or '' end,
      fg = function() return get_hex('Normal', 'fg') end
    },
    {
      text = function(buffer) return '    ' .. buffer.devicon.icon end,
      fg = function(buffer) return buffer.devicon.color end,
    },
    {
      text = function(buffer) return buffer.filename .. '    ' end,
      bold = function(buffer) return buffer.is_focused end
    },
    {
      text = '󰖭',
      on_click = function(_, _, _, _, buffer)
        buffer:delete()
      end
    },
    {
      text = '  ',
    },
  },
})
```

</details>

![cokeline-bufferline-lua](https://user-images.githubusercontent.com/38540736/226447803-13f3d3ee-454f-42be-81b4-9254f95503e4.png)

<!-- panvimdoc-ignore-end -->

### Dynamic rendering

<!-- ### Dynamic rendering (with sliders) -->

Even when you have a lot of buffers open, `nvim-cokeline` is rendered to always
keep the focused buffer visible and in the middle of the bufferline. Also, if a
buffer doesn't fit entirely we still try to include as much of it as possible
before cutting off the rest.

<!-- panvimdoc-ignore-start -->

![rendering](https://user-images.githubusercontent.com/38540736/226447817-4f3679c8-a10a-48ad-8329-b21c3ee54968.gif)

<!-- panvimdoc-ignore-end -->

### LSP support

If a buffer has an LSP client attached to it, you can configure the style of a
component to change based on how many errors, warnings, infos and hints are
reported by the LSP.

<!-- panvimdoc-ignore-start -->

![lsp-styling](https://user-images.githubusercontent.com/38540736/226447813-4ec42530-9e86-43f5-98ed-fd7b4012120b.gif)

<!-- panvimdoc-ignore-end -->

### Buffer pick

You can focus and close any buffer by typing its `pick_letter`. Letters are
assigned by filename by default (e.g. `foo.txt` gets the letter `f`), and by
keyboard reachability if the letter is already assigned to another buffer.

<!-- panvimdoc-ignore-start -->

<details>
<summary>Click to see configuration</summary>

```lua
local is_picking_focus = require('cokeline.mappings').is_picking_focus
local is_picking_close = require('cokeline.mappings').is_picking_close
local get_hex = require('cokeline.hlgroups').get_hl_attr

local red = vim.g.terminal_color_1
local yellow = vim.g.terminal_color_3

require('cokeline').setup({
  default_hl = {
    fg = function(buffer)
      return
        buffer.is_focused
        and get_hex('Normal', 'fg')
         or get_hex('Comment', 'fg')
    end,
    bg = function() return get_hex('ColorColumn', 'bg') end,
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
      fg = function(buffer)
        return
          (is_picking_focus() and yellow)
          or (is_picking_close() and red)
          or buffer.devicon.color
      end,
      italic = function()
        return
          (is_picking_focus() or is_picking_close())
      end,
      bold = function()
        return
          (is_picking_focus() or is_picking_close())
      end
    },
    {
      text = ' ',
    },
    {
      text = function(buffer) return buffer.filename .. '  ' end,
      bold = function(buffer) return buffer.is_focused end,
    },
    {
      text = '',
      on_click = function(_, _, _, _, buffer)
        buffer:delete()
      end,
    },
    {
      text = '  ',
    },
  },
})
```

</details>

![buffer-pick](https://user-images.githubusercontent.com/38540736/226447793-8e2341b3-e454-49dc-af84-72d3b56f40d3.gif)

<!-- panvimdoc-ignore-end -->

### Sidebars

You can add a left sidebar to integrate nicely with file explorer plugins like
[nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua),
[CHADTree](https://github.com/ms-jpq/chadtree) or
[NERDTree](https://github.com/preservim/nerdtree).

<!-- panvimdoc-ignore-start -->

<details>
<summary>Click to see configuration</summary>

```lua
local get_hex = require('cokeline.hlgroups').get_hl_attr

local yellow = vim.g.terminal_color_3

require('cokeline').setup({
  default_hl = {
    fg = function(buffer)
      return
        buffer.is_focused
        and get_hex('Normal', 'fg')
         or get_hex('Comment', 'fg')
    end,
    bg = function() return get_hex('ColorColumn', 'bg') end,
  },

  sidebar = {
    filetype = {'NvimTree', 'neo-tree'},
    components = {
      {
        text = function(buf)
          return buf.filetype
        end,
        fg = yellow,
        bg = function() return get_hex('NvimTreeNormal', 'bg') end,
        bold = true,
      },
    }
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
      fg = function(buffer)
        return buffer.devicon.color
      end,
    },
    {
      text = ' ',
    },
    {
      text = function(buffer) return buffer.filename .. '  ' end,
      bold = function(buffer)
        return buffer.is_focused
      end,
    },
    {
      text = '',
      on_click = function(_, _, _, _, buffer)
        buffer:delete()
      end,
    },
    {
      text = '  ',
    },
  },
})
```

</details>

![sidebars](https://user-images.githubusercontent.com/38540736/226447821-de543b87-909c-445f-ac6e-82f5f6bbf9aa.png)

<!-- panvimdoc-ignore-end -->

### Unique buffer names

When files with the same filename belonging to different directories are opened
simultaneously, you can include a unique filetree prefix to distinguish between
them:

<!-- panvimdoc-ignore-start -->

![unique-prefix](https://user-images.githubusercontent.com/38540736/226447822-3315ad2f-35c9-4fc3-a777-c01cd8f2fe46.gif)

<!-- panvimdoc-ignore-end -->

### Clickable buffers

Left click on a buffer to focus it, and right click to delete it. Alternatively, define custom click handlers for each component that override the default behavior.

<!-- panvimdoc-ignore-start -->

![clickable-buffers](https://user-images.githubusercontent.com/38540736/226447799-e845d266-0658-44e3-bd89-f706577844bf.gif)

<!-- panvimdoc-ignore-end -->

### Hover events

Each component has access to an is_hovered property, and can be given custom `on_mouse_enter` and `on_mouse_leave` handlers, allowing for implementations of close buttons, diagnostic previews, and more complex funcionality.

Note: requires `:h 'mousemoveevent'`

<!-- panvimdoc-ignore-start -->

![hover-events](https://github.com/willothy/nvim-cokeline/assets/38540736/fb92475f-d775-44fe-9c95-a76c1cbaf560)

![hover-events-2](https://github.com/willothy/nvim-cokeline/assets/38540736/3b319c79-0bff-41dd-9a08-36fd627b3d08)

<!-- panvimdoc-ignore-end -->

### Buffer re-ordering (including mouse-drag reordering)

<!-- panvimdoc-ignore-start -->

![reordering](https://user-images.githubusercontent.com/38540736/226447818-bdf63d70-e153-4353-992d-d317a5764c09.gif)

<!-- panvimdoc-ignore-end -->

### Close icons

<!-- panvimdoc-ignore-start -->

![close-icons](https://user-images.githubusercontent.com/38540736/226447802-29b2919e-dd20-4789-8d6a-250d6d453c64.gif)

<!-- panvimdoc-ignore-end -->

### Buffer history tracking

```lua
require("cokeline.history"):last():focus()
```

If you are a user of [`resession.nvim`](https://github.com/stevearc/resession.nvim), cokeline's history will be restored along with
the rest of your sessions.

## :electric_plug: Requirements

The two main requirements are Neovim 0.5+ and the `termguicolors` option to be
set. If you want to display devicons in your bufferline you'll also need the
[nvim-tree/nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons)
plugin and a patched font (see [Nerd Fonts](https://www.nerdfonts.com/)).

As of v0.4.0, [nvim-lua/plenary.nvim](https://github.com/nvim-lua/plenary.nvim) is required as well.

## :package: Installation

### Lua

#### With lazy.nvim

```lua
require("lazy").setup({
  {
  "willothy/nvim-cokeline",
  dependencies = {
    "nvim-lua/plenary.nvim",        -- Required for v0.4.0+
    "nvim-tree/nvim-web-devicons", -- If you want devicons
    "stevearc/resession.nvim"       -- Optional, for persistent history
  },
  config = true
}
})
```

### Vimscript

If your config is still written in Vimscript and you use
[vim-plug](https://github.com/junegunn/vim-plug):

```vim
call plug#begin('~/.config/nvim/plugged')
  " ...
  Plug 'nvim-lua/plenary.nvim'        " Required for v0.4.0+
  Plug 'nvim-tree/nvim-web-devicons' " If you want devicons
  Plug 'willothy/nvim-cokeline'
  " ...
call plug#end()

set termguicolors
lua << EOF
  require('cokeline').setup()
EOF
```

## :wrench: Configuration

> **note**<br>
> Check out the [wiki](https://github.com/willothy/nvim-cokeline/wiki) for more details and API documentation.

All the configuration is done by changing the contents of the Lua table passed to
the `setup` function.

The valid keys are:

```lua
require('cokeline').setup({
  -- Only show the bufferline when there are at least this many visible buffers.
  -- default: `1`.
  ---@type integer
  show_if_buffers_are_at_least = 1,

  buffers = {
    -- A function to filter out unwanted buffers. Takes a buffer table as a
    -- parameter (see the following section for more infos) and has to return
    -- either `true` or `false`.
    -- default: `false`.
    ---@type false | fun(buf: Buffer):boolean
    filter_valid = false,

    -- A looser version of `filter_valid`, use this function if you still
    -- want the `cokeline-{switch,focus}-{prev,next}` mappings to work for
    -- these buffers without displaying them in your bufferline.
    -- default: `false`.
    ---@type false | fun(buf: Buffer):boolean
    filter_visible = false,

    -- Which buffer to focus when a buffer is deleted, `prev` focuses the
    -- buffer to the left of the deleted one while `next` focuses the one the
    -- right.
    -- default: 'next'.
    focus_on_delete = 'prev' | 'next',

    -- If set to `last` new buffers are added to the end of the bufferline,
    -- if `next` they are added next to the current buffer.
    -- if set to `directory` buffers are sorted by their full path.
    -- if set to `number` buffers are sorted by bufnr, as in default Neovim
    -- default: 'last'.
    ---@type 'last' | 'next' | 'directory' | 'number' | fun(a: Buffer, b: Buffer):boolean
    new_buffers_position = 'last',

    -- If true, right clicking a buffer will close it
    -- The close button will still work normally
    -- Default: true
    ---@type boolean
    delete_on_right_click = true,
  },

  mappings = {
    -- Controls what happens when the first (last) buffer is focused and you
    -- try to focus/switch the previous (next) buffer. If `true` the last
    -- (first) buffers gets focused/switched, if `false` nothing happens.
    -- default: `true`.
    ---@type boolean
    cycle_prev_next = true,

    -- Disables mouse mappings
    -- default: `false`.
    ---@type boolean
    disable_mouse = false,
  },

  -- Maintains a history of focused buffers using a ringbuffer
  history = {
    ---@type boolean
    enabled = true,
    ---The number of buffers to save in the history
    ---@type integer
    size = 2
  },

  rendering = {
    -- The maximum number of characters a rendered buffer is allowed to take
    -- up. The buffer will be truncated if its width is bigger than this
    -- value.
    -- default: `999`.
    ---@type integer
    max_buffer_width = 999,
  },

  pick = {
    -- Whether to use the filename's first letter first before
    -- picking a letter from the valid letters list in order.
    -- default: `true`
    ---@type boolean
    use_filename = true,

    -- The list of letters that are valid as pick letters. Sorted by
    -- keyboard reachability by default, but may require tweaking for
    -- non-QWERTY keyboard layouts.
    -- default: `'asdfjkl;ghnmxcvbziowerutyqpASDFJKLGHNMXCVBZIOWERTYQP'`
    ---@type string
    letters = 'asdfjkl;ghnmxcvbziowerutyqpASDFJKLGHNMXCVBZIOWERTYQP',
  },

  -- The default highlight group values.
  -- The `fg`, `bg`, and `sp` keys are either colors in hexadecimal format or
  -- functions taking a `buffer` parameter and returning a color in
  -- hexadecimal format. Style attributes work the same way, but functions
  -- should return boolean values.
  default_hl = {
    -- default: `ColorColumn`'s background color for focused buffers,
    -- `Normal`'s foreground color for unfocused ones.
    ---@type nil | string | fun(buffer: Buffer): string
    fg = function(buffer)
      local hlgroups = require("cokeline.hlgroups")
      return buffer.is_focused and hlgroups.get_hl_attr("ColorColumn", "bg")
        or hlgroups.get_hl_attr("Normal", "fg")
    end,

    -- default: `Normal`'s foreground color for focused buffers,
    -- `ColorColumn`'s background color for unfocused ones.
    -- default: `Normal`'s foreground color.
    ---@type nil | string | function(buffer: Buffer): string,
    bg = function(buffer)
      local hlgroups = require("cokeline.hlgroups")
      return buffer.is_focused and hlgroups.get_hl_attr("Normal", "fg")
        or hlgroups.get_hl_attr("ColorColumn", "bg")
    end,

    -- default: unset.
    ---@type nil | string | function(buffer): string,
    sp = nil,

    ---@type nil | boolean | fun(buf: Buffer):boolean
    bold = nil,
    ---@type nil | boolean | fun(buf: Buffer):boolean
    italic = nil,
    ---@type nil | boolean | fun(buf: Buffer):boolean
    underline = nil,
    ---@type nil | boolean | fun(buf: Buffer):boolean
    undercurl = nil,
    ---@type nil | boolean | fun(buf: Buffer):boolean
    strikethrough = nil,
  },

  -- The highlight group used to fill the tabline space
  fill_hl = 'TabLineFill',

  -- A list of components to be rendered for each buffer. Check out the section
  -- below explaining what this value can be set to.
  -- default: see `/lua/cokeline/config.lua`
  ---@type Component[]
  components = {},

  -- Custom areas can be displayed on the right hand side of the bufferline.
  -- They act identically to buffer components, except their methods don't take a Buffer object.
  -- If you want a rhs component to be stateful, you can wrap it in a closure containing state.
  ---@type Component[] | false
  rhs = {},

  -- Tabpages can be displayed on either the left or right of the bufferline.
  -- They act the same as other components, except they are passed TabPage objects instead of
  -- buffer objects.
  ---@type table | false
  tabs = {
    placement = "left" | "right",
    ---@type Component[]
    components = {}
  },

  -- Left sidebar to integrate nicely with file explorer plugins.
  -- This is a table containing a `filetype` key and a list of `components` to
  -- be rendered in the sidebar.
  -- The last component will be automatically space padded if necessary
  -- to ensure the sidebar and the window below it have the same width.
  ---@type table | false
  sidebar = {
    ---@type string | string[]
    filetype = { "NvimTree", "neo-tree", "SidebarNvim" },
    ---@type Component[]
    components = {},
  },
})
```

### So what's `function(buffer)`?

Some of the configuration options can be functions that take a [`Buffer`](https://github.com/willothy/nvim-cokeline/wiki/Buffer) as a
single parameter. This is useful as it allows users to set the values of
components dynamically based on the buffer that component is being rendered
for.

The `Buffer` type is just a Lua table with the following keys:

```lua
Buffer = {
  -- The buffer's order in the bufferline (1 for the first buffer, 2 for the
  -- second one, etc.).
  index = int,

  -- The buffer's internal number as reported by `:ls`.
  number = int,

  ---@type boolean
  is_focused = false,

  ---@type boolean
  is_modified = false,

  ---@type boolean
  is_readonly = false,

  -- The buffer is the first visible buffer in the tab bar
  ---@type boolean
  is_first    = false,

  -- The buffer is the last visible buffer in the tab bar
  ---@type boolean
  is_last     = false,

  -- The mouse is hovering over the current component in the buffer
  -- This is a special variable in that it will only be true for the hovered *component*
  -- on render. This is to allow components to respond to hover events individually without managing
  -- component state.
  ---@type boolean
  is_hovered  = false,

  -- The mouse is hovering over the buffer (true for all components)
  ---@type boolean
  buf_hovered = false,

  -- The buffer's type as reported by `:echo &buftype`.
  ---@type string
  ---@type string
  type = '',

  -- The buffer's filetype as reported by `:echo &filetype`.
  ---@type string
  filetype = '',

  -- The buffer's full path.
  ---@type string
  path = '',

  -- The buffer's filename.
  ---@type string
  filename = 'string',

  -- A unique prefix used to distinguish buffers with the same filename
  -- stored in different directories. For example, if we have two files
  -- `bar/foo.md` and `baz/foo.md`, then the first will have `bar/` as its
  -- unique prefix and the second one will have `baz/`.
  ---@type string
  unique_prefix = '',

  -- The letter that is displayed when picking a buffer to either focus or
  -- close it.
  ---@type string
  pick_letter = 'char',

  -- This needs the `nvim-tree/nvim-web-devicons` plugin to be installed.
  devicon = {
    -- An icon representing the buffer's filetype.
    ---@type string
    icon = 'string',

    -- The colors of the devicon in hexadecimal format (useful to be passed
    -- to a component's `fg` field (see the `Components` section).
    color = '#rrggbb',
  },

  -- The values in this table are the ones reported by Neovim's built in
  -- LSP interface.
  diagnostics = {
    ---@type integer
    errors = 0,
    ---@type integer
    warnings = 0,
    ---@type integer
    infos = 0,
    ---@type integer
    hints = 0,
  },
}
```

It also has methods that can be used in component event handlers:

```lua
---@param self Buffer
---Deletes the buffer
function Buffer:delete() end

---@param self Buffer
---Focuses the buffer
function Buffer:focus() end

---@param self Buffer
---@return number
---Returns the number of lines in the buffer
function Buffer:lines() end

---@param self Buffer
---@return string[]
---Returns the buffer's lines
function Buffer:text() end

---@param buf Buffer
---@return boolean
---Returns true if the buffer is valid
function Buffer:is_valid() end
```

### What about [`TabPage`](https://github.com/willothy/nvim-cokeline/wiki/TabPage)s?

Each method on a tab component is passed a `TabPage` object as an argument.

`TabPage`, like `Buffer`, is simply a Lua table with some relevant data attached.

```lua
TabPage = {
  -- The tabpage number, as reported by `nvim_list_tabpages`
  ---@type integer
  number = 0,
  -- A list of Window objects contained in the TabPage (see wiki for more info)
  ---@type Window[]
  windows = {},
  -- The currently focused window in the TabPage
  ---@type Window
  focused = nil,
  -- True if the TabPage is the current TabPage
  ---@type boolean
  is_active = true,
  -- True if the TabPage is first in the list
  ---@type boolean
  is_first = false,
  -- True if the TabPage is last in the list
  ---@type boolean
  is_last = false
}
```

### And [`components`](https://github.com/willothy/nvim-cokeline/wiki/Component)?

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
      text = '󰅖',
      on_click = function(_, _, _, _, buffer)
        buffer:delete()
      end
    },
    {
      text = ' ',
    }
  }
})
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

  ---@type string | fun(buffer: Buffer): string
  text = "",

  -- The foreground, backgrond and style of the component
  ---@type nil | string | fun(buffer: Buffer): string
  fg = '#rrggbb',
  ---@type nil | string | fun(buffer: Buffer): string
  bg = '#rrggbb',
  ---@type nil | string | fun(buffer: Buffer): string
  sp = '#rrggbb',
  ---@type nil | boolean | fun(buffer: Buffer): boolean
  bold = false,
  ---@type nil | boolean | fun(buffer: Buffer): boolean
  italic = false,
  ---@type nil | boolean | fun(buffer: Buffer): boolean
  underline = false,
  ---@type nil | boolean | fun(buffer: Buffer): boolean
  undercurl = false,
  ---@type nil | boolean | fun(buffer: Buffer): boolean
  strikethrough = false,

  -- Or, alternatively, the name of the highlight group
  ---@type nil | string | fun(buffer: Buffer): string
  highlight = nil,

  -- If `true` the buffer will be deleted when this component is
  -- left-clicked (usually used to implement close buttons, overrides `on_click`).
  -- deprecated, it is recommended to use the Buffer:delete() method in an on_click event
  -- to implement close buttons instead.
  ---@type boolean
  delete_buffer_on_left_click = false,

  -- Handles click event for a component
  -- If not set, component will have the default click behavior
  -- buffer is a Buffer object, not a bufnr
  ---@type nil | fun(idx: integer, clicks: integer, button: string, mods: string, buffer: Buffer)
  on_click = nil,

  -- Called on a component when hovered
  ---@type nil | function(buffer: Buffer, mouse_col: integer)
  on_mouse_enter = nil,

  -- Called on a component when unhovered
  ---@type nil | function(buffer: Buffer, mouse_col: integer)
  on_mouse_leave = nil,

  truncation = {
    -- default: index of the component in the `components` table (1 for the
    -- first component, 2 for the second, etc.).
    ---@type integer
    priority = 1,

    -- default: `right`.
    ---@type 'left' | 'middle' | 'right'
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
_after_ a component with a priority of 6, even though 6 > 5.

The `truncation.direction` key simply controls from which direction a component
is shortened. For example, you might want to set the `truncation.direction` of
a component displaying a filename to `'middle'` or `'left'`, so that if
the filename has to be shortened you'll still be able to see its extension,
like in the following example (where it's set to `'left'`):

<!-- panvimdoc-ignore-start -->

![buffer-truncation](https://user-images.githubusercontent.com/38540736/226447798-6aee2e0f-f957-42ab-96dd-3618e78ba4ba.png)

<!-- panvimdoc-ignore-end -->

#### What about [`history`](https://github.com/willothy/nvim-cokeline/wiki/History)?

The History keeps track of the buffers you access using a ringbuffer, and provides
an API for accessing Buffer objects from the history.

You can access the history using `require("cokeline.history")`, or through the global `_G.cokeline.history`.

The `History` object provides these methods:

```lua
History = {}

---Adds a Buffer object to the history
---@type bufnr integer
function History:push(bufnr)
end

---Removes and returns the oldest Buffer object in the history
---@return Buffer?
function History:pop()
end

---Returns a list of Buffer objects in the history,
---ordered from oldest to newest
---@return Buffer[]
function History:list()
end

---Returns an iterator of Buffer objects in the history,
---ordered from oldest to newest
---@return fun(): Buffer?
function History:iter()
end

---Get a Buffer object by history index
---@param idx integer
---@return Buffer?
function History:get(idx)
end

---Get a Buffer object representing the last-accessed buffer (before the current one)
---@return Buffer?
function History:last()
end

---Returns true if the history is empty
---@return boolean
function History:is_empty()
end

---Returns the maximum number of buffers that can be stored in the history
---@return integer
function History:capacity()
end

---Returns true if the history contains the given buffer
---@param bufnr integer
---@return boolean
function History:contains(bufnr)
end

---Returns the number of buffers in the history
---@return integer
function History:len()
end
```

## :musical_keyboard: Mappings

You can use the `mappings` module to create mappings from Lua:

```lua
vim.keymap.set("n", "<leader>bp", function()
    require('cokeline.mappings').pick("focus")
end, { desc = "Pick a buffer to focus" })
```

Alternatively, we expose the following `<Plug>` mappings which can be used as the right hand
side of other mappings:

```
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

map("n", "<S-Tab>", "<Plug>(cokeline-focus-prev)", { silent = true })
map("n", "<Tab>", "<Plug>(cokeline-focus-next)", { silent = true })
map("n", "<Leader>p", "<Plug>(cokeline-switch-prev)", { silent = true })
map("n", "<Leader>n", "<Plug>(cokeline-switch-next)", { silent = true })

for i = 1, 9 do
  map(
    "n",
    ("<F%s>"):format(i),
    ("<Plug>(cokeline-focus-%s)"):format(i),
    { silent = true }
  )
  map(
    "n",
    ("<Leader>%s"):format(i),
    ("<Plug>(cokeline-switch-%s)"):format(i),
    { silent = true }
  )
end

```
