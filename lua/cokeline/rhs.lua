local lazy = require("cokeline.lazy")
local state = lazy("cokeline.state")
local components = lazy("cokeline.components")
local RenderContext = lazy("cokeline.context")

local M = {}

---@class RhsContext
---@field is_hovered boolean

function M.get_components()
  local hovered = lazy("cokeline.hover").hovered()
  local rhs = {}
  for _, c in ipairs(state.rhs) do
    local is_hovered = hovered and hovered.index == c.index
    table.insert(
      rhs,
      c:render(RenderContext:rhs({
        is_hovered = is_hovered,
      }, "rhs"))
    )
  end
  return rhs
end

function M.width()
  return components.width(M.get_components())
end

return M
