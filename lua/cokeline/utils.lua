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
local wrapper_handler_click = function (bufnr, clicks, click)
  _G.cokeline.config.handler_click(buffers.get_buffer(bufnr), clicks, click)
end

return {
  get_hex = get_hex,
  wrapper_handler_click = wrapper_handler_click
}
