local components = require("cokeline/components")
local Component = components.Component

local function get_ctx()
  return _G.cokeline.rhs.context
end

local function get_components()
  local rhs = {}
  for i, c in ipairs(_G.cokeline.rhs.components) do
    rhs[i] = c:render(get_ctx())
  end
  return rhs
  -- return _G.cokeline.rhs.components
end

local function width()
  -- local width = 0
  -- for _, c in ipairs(get_components()) do
  --   print(vim.inspect(c))
  --   width = width + c:render(get_ctx())
  -- end
  -- return width
  return components.width(get_components())
end

-- Takes in a list of components, returns the concatenation of their rendered
-- strings.
---@param components  Component[]
---@return string
local render_components = function(components)
  local embed = function(component)
    local text = component.hlgroup:embed(component.text)
    if not vim.fn.has("tablineat") then
      return text
    else
      -- local on_click = "CokelineHandleClick"
      -- return ("%%%s@%s@%s%%X"):format(component.bufnr, on_click, text)
      return ("%s"):format(text)
    end
  end

  return table.concat(vim.tbl_map(function(component)
    return embed(component)
  end, components))
end

local function render()
  -- update dynamic context providers
  -- for i, ctx_provider in ipairs(RHS.ctx) do
  --   if type(ctx_provider) == "function" then
  --     RHS.ctx[i] = ctx_provider()
  --   end
  -- end

  -- return components.render(get_components())
  return render_components(get_components())
end

return {
  render = render,
  width = width,
}
