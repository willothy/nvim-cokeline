local components = require("cokeline.components")
local RenderContext = require("cokeline.context")

local M = {}

function M.get_components()
  local hovered = require("cokeline.hover").hovered()
  local rhs = {}
  for _, c in ipairs(_G.cokeline.rhs) do
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
