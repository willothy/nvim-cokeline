---@alias ContextKind '"buffer"' | '"tab"' | '"rhs"'

---@class RenderContext
---@field kind ContextKind
---@field provider Buffer | Tab
local RenderContext = {
  kind = "buffer",
}

---@param kind ContextKind
---@param provider Buffer | Tab | RhsContext
---@return RenderContext
function RenderContext:new(provider, kind)
  return setmetatable({ provider = provider, kind = kind }, { __index = self })
end

return RenderContext
