local Buffer = require("cokeline/buffers").Buffer
local Component = require("cokeline/components").Component
local components = require("cokeline/components")

local min = math.min
local rep = string.rep
local insert = table.insert
local sort = table.sort

local api = vim.api
local bo = vim.bo
local fn = vim.fn
local o = vim.o

---@return Component[]
local get_components = function()
  local layout = fn.winlayout()

  -- If the first split level is not given by vertically split windows we
  -- return early.
  if layout[1] ~= "row" then
    return {}
  end

  -- The second element of the `layout` table is a nested list representing the
  -- tree of vertically split windows in a tabpage. For example, for a layout
  -- like.
  -- +-----+-----+-----+
  -- |     |     |  C  |
  -- |  A  |  B  |-----|
  -- |     |     |  D  |
  -- +-----+-----+-----+
  -- the associated tree would be
  --        / | \
  --       /  |  \
  --      A   B  / \
  --             C  D
  -- where each leaf is represented as a `{'leaf', <winid>}` table.
  local window_tree = layout[2]

  -- Since we're checking if we need to display sidebars we're only
  -- interested in the first and last window splits.
  local first_split = window_tree[1]
  if first_split[1] ~= "leaf" then
    return {}
  end

  local winid = first_split[2]
  local bufnr = api.nvim_win_get_buf(winid)

  if bo[bufnr].filetype ~= _G.cokeline.config.sidebar.filetype then
    return {}
  end

  local buffer = Buffer.new({
    bufnr = bufnr,
    name = fn.bufname(4),
  })

  local sidebar_components = {}
  local width = 0
  for i, c in ipairs(_G.cokeline.config.sidebar.components) do
    local component = Component.new(c, i):render(buffer)
    if component.width > 0 then
      insert(sidebar_components, component)
      width = width + component.width
    end
  end

  local sidebar_width = min(api.nvim_win_get_width(winid), o.columns)
  local rendering = require("cokeline/rendering")

  if width > sidebar_width then
    sort(sidebar_components, rendering.by_decreasing_priority)
    components.shorten(sidebar_components, sidebar_width)
    sort(sidebar_components, rendering.by_decreasing_index)
  elseif width < sidebar_width then
    local space_left = sidebar_width - width
    local last = #sidebar_components
    sidebar_components[last].text = sidebar_components[last].text
      .. rep(" ", space_left)
    sidebar_components[last].width = sidebar_components[last].width
      + space_left
  end

  return sidebar_components
end

return {
  get_components = get_components,
}
