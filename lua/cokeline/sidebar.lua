local Buffer = require("cokeline/buffers").Buffer
local components = require("cokeline/components")
local RenderContext = require("cokeline/context")

local min = math.min
local rep = string.rep
local insert = table.insert
local sort = table.sort

local api = vim.api
local bo = vim.bo
local fn = vim.fn
local o = vim.o

---@return Component<SidebarContext>[]
local get_components = function()
  if not _G.cokeline.config.sidebar then
    return {}
  end

  local hover = require("cokeline/hover").hovered()
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
  --
  -- However, with edgy.nvim, a sidebar can contain multiple splits nested one level in.
  -- So if the first window found is a leaf, we check the first window of the container.
  local first_split = window_tree[1]
  local winid = first_split[2]
  if first_split[1] ~= "leaf" then
    local win = first_split[2][1]
    if win and win[1] == "leaf" then
      winid = win[2]
    else
      return {}
    end
  end

  local bufnr = api.nvim_win_get_buf(winid)

  if type(_G.cokeline.config.sidebar.filetype) == "table" then
    if
      not vim.tbl_contains(
        _G.cokeline.config.sidebar.filetype,
        bo[bufnr].filetype
      )
    then
      return {}
    end
  else
    if bo[bufnr].filetype ~= _G.cokeline.config.sidebar.filetype then
      return {}
    end
  end

  local buffer = Buffer.new({
    bufnr = bufnr,
    name = fn.bufname(4),
  })
  local sidebar_width = min(api.nvim_win_get_width(winid), o.columns)

  local sidebar_components = {}
  local width = 0
  local id = #_G.cokeline.components + #_G.cokeline.rhs + 1
  for _, c in ipairs(_G.cokeline.sidebar) do
    buffer.is_hovered = hover and hover.index == id
    local component = c:render(RenderContext:buffer(buffer))
    buffer.is_hovered = false
    -- We need at least one component, otherwise we can't add padding to the
    -- last component if needed.
    if component.width > 0 or #sidebar_components == 0 then
      insert(sidebar_components, component)
      width = width + component.width
    end
    id = id + 1
  end

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
