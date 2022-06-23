local augroups = require("cokeline/augroups")
local buffers = require("cokeline/buffers")
local config = require("cokeline/config")
local mappings = require("cokeline/mappings")
local rendering = require("cokeline/rendering")

local fn = vim.fn
local opt = vim.opt

---Global table used to manage the plugin's state.
_G.cokeline = {
  ---@type Component[]
  components = {},

  ---@type table
  config = {},

  ---@type fun(): string
  tabline = nil,

  ---@type Buffer[]
  valid_buffers = {},

  ---@type Buffer[]
  visible_buffers = {},
}

---@param preferences table|nil
local setup = function(preferences)
  _G.cokeline.config = config.get(preferences or {})
  augroups.setup()
  mappings.setup()

  if fn.has("tablineat") then
    vim.cmd([[
      function! CokelineHandleClick(minwid, clicks, button, modifiers)
        execute printf('lua require("cokeline.utils").wrapper_handler_click(%s, "%s", %d)', a:minwid, a:button, a:clicks)
      endfunction

      function! CokelineHandleClickComponent(minwid, clicks, button, modifiers)
        execute printf('lua require("cokeline.utils").wrapper_handler_click_component(%s, "%s", %d)', a:minwid, a:button, a:clicks)
      endfunction
    ]])
  end

  opt.showtabline = 2
  opt.tabline = "%!v:lua.cokeline.tabline()"
end

---@return string
_G.cokeline.tabline = function()
  local visible_buffers = buffers.get_visible()
  if #visible_buffers < _G.cokeline.config.show_if_buffers_are_at_least then
    opt.showtabline = 0
    return
  end
  return rendering.render(visible_buffers)
end

return {
  setup = setup,
}
