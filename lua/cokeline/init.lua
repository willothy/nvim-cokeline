local augroups = require('cokeline/augroups')
local defaults = require('cokeline/defaults')
local highlights = require('cokeline/highlights')
local utils = require('cokeline/utils')
local fn = vim.fn
local M = {}

local function get_state()
  local state = {
    buffers = {},
  }
  for i, buf in pairs(fn.getbufinfo({buflisted=1})) do
    local is_focused = buf.bufnr == fn.bufnr('%')
    local hl = (is_focused and 'CokeFocused') or 'CokeUnfocused'
    local title = [[%#]]..hl..[[#]]..buf.name..[[%*]]
    table.insert(state.buffers, title)
  end
  return state
end

function cokeline()
  state = get_state()
  return table.concat(state.buffers, ' | ')
end

-- function M.redraw()
--   vim.cmd('redrawtabline')
-- end

function M.toggle()
  local buffers = fn.getbufinfo({buflisted=1})
  vim.o.showtabline = (#buffers > 1 and 2) or 0
end

function M.setup(preferences)
  local settings = utils.update(defaults, preferences)
  augroups.setup(settings)
  highlights.setup(settings.colors)
  vim.o.tabline = '%!v:lua.cokeline()'
end

return M
