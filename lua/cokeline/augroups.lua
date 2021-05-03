local vimcmd = vim.cmd
local format = string.format
local M = {}

local function create_augroups(augroups)
  for _, group in pairs(augroups) do
    vimcmd(format('augroup %s', group.name))
    vimcmd('autocmd!')
    for _, cmd in pairs(group.autocmds) do
      vimcmd(format('autocmd %s %s %s', cmd.event, cmd.target, cmd.command))
    end
    vimcmd('augroup END')
  end
end

function M.setup(settings)
  local augroups = {}
  -- TODO
  -- BufEnter is excessive. BufAdd and BufDelete should be enough, but
  -- BufDelete is triggered before the buffer is actually unlisted, which means
  -- toggle() will count two buffers, not one. See
  -- https://neovim.io/doc/user/autocmd.html#%7Bevent%7D
  if settings.hide_when_one_buffer then
    table.insert (
      augroups,
      {
        name = 'cokeline_toggle',
        autocmds = {
          {
            event = 'BufEnter',
            target = '*',
            command = 'lua require"cokeline".toggle()',
          }
        }
      }
    )
  end
  create_augroups(augroups)
end

return M
