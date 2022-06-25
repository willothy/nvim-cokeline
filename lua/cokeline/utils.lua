local vim_fn = vim.fn
local buffers = require("cokeline/buffers")

---Returns the color set by the current colorscheme for the `attr` attribute of
---the `hlgroup_name` highlight group in hexadecimal format.
---@param hlgroup_name  string
---@param attr  '"fg"' | '"bg"'
---@return string
local get_hex = function(hlgroup_name, attr)
  local hlgroup_ID = vim_fn.synIDtrans(vim_fn.hlID(hlgroup_name))
  local hex = vim_fn.synIDattr(hlgroup_ID, attr)
  return hex ~= "" and hex or "NONE"
end

---Wrapper handler click
---@param bufnr number
---@param clicks number
---@param click string
local wrapper_handle_click = function (bufnr, clicks, click)
  local buffer = buffers.get_buffer(bufnr)

  if buffer then
    _G.cokeline.config.handle_click(buffer, clicks, click)
  end
end

---Wrapper handler component click
---@param bufnr number
---@param clicks number
---@param click string
local wrapper_handle_click_component = function (bufnr, clicks, click)
  local buffer = buffers.get_buffer(bufnr)

  if buffer then
    _G.cokeline.config.handle_click_component(buffer, clicks, click)
  end
end

return {
  get_hex = get_hex,
  wrapper_handle_click = wrapper_handle_click,
  wrapper_handle_click_component = wrapper_handle_click_component
}
