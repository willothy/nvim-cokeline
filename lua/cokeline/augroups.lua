local utils = require('cokeline/utils')
local M = {}

function M.setup(settings)
  augroups = {}

  -- table.insert(augroups,
  --   {
  --     name = 'cokeline_redraw',
  --     autocmds = {{
  --       event='BufEnter',
  --       target='*',
  --       command=[[lua require('cokeline').redraw()]],
  --     }}
  --   })

  if settings.hide_when_one_buffer then
    -- TODO
    -- BufEnter is excessive. BufAdd and BufDelete should be enough, but
    -- BufDelete is triggered before the buffer is actually unlisted, which
    -- means toggle() will count two buffers, not one. See
    -- https://neovim.io/doc/user/autocmd.html#%7Bevent%7D
    table.insert(augroups,
      {
        name = 'cokeline_toggle',
        autocmds = {{
          event='BufEnter',
          target='*',
          command=[[lua require('cokeline').toggle()]],
        }}
      })
  end

  utils.create_augroups(augroups)
end

return M
