---@alias ContextKind '"buffer"' | '"tab"'

---@class RenderContext
---@field kind ContextKind
---@field provider Buffer | Tab
local RenderContext = {
  kind = "buffer",
}

---@param kind ContextKind
---@param provider Buffer | Tab
---@return RenderContext
function RenderContext:new(provider, kind)
  return vim.tbl_extend("keep", { provider = provider, kind = kind }, self)
end

return RenderContext
