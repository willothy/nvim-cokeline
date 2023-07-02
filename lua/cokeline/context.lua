---@alias ContextKind "buffer" | "tab" | "rhs" | "sidebar"

---@class RenderContext
---@field kind ContextKind
---@field provider Buffer | TabPage | RhsContext | SidebarContext
local RenderContext = {}

---@param tab TabPage
function RenderContext:tab(tab)
  return {
    provider = tab,
    kind = "tab",
  }
end

---@param rhs RhsContext
function RenderContext:rhs(rhs)
  return {
    provider = rhs,
    kind = "rhs",
  }
end

---@param buffer Buffer
function RenderContext:buffer(buffer)
  return {
    provider = buffer,
    kind = "buffer",
  }
end

---@param sidebar SidebarContext
function RenderContext:sidebar(sidebar)
  return {
    provider = sidebar,
    kind = "sidebar",
  }
end

return RenderContext
