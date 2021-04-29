local utils = require('cokeline/utils')
local M = {}

local defaults = {
  hide_when_one_buffer = false,
}

local function setup_augroups(settings)
  augroups = {}
  if settings.hide_when_one_buffer then
    -- TODO
    -- BufEnter is excessive. BufAdd and BufDelete should be enough, but
    -- BufDelete is triggered before the buffer is actually unlisted, which
    -- means toggle() will count two buffers, not one. See
    -- https://neovim.io/doc/user/autocmd.html#%7Bevent%7D
    table.insert(augroups,
      {
        name = 'toggle_cokeline',
        autocmds = {{
          event='BufEnter',
          target='*',
          command=[[lua require('cokeline').toggle()]],
        }}
      })
  end
  utils.create_augroups(augroups)
end

local function cokeline(settings)
  return '%f'
end

function M.toggle()
  local buffers = vim.fn.getbufinfo({buflisted=1})
  vim.o.showtabline = (#buffers > 1 and 2) or 0
end

function M.setup(preferences)
  local settings = utils.update(defaults, preferences)
  setup_augroups(settings)
  vim.o.tabline = cokeline(settings)
end

return M
