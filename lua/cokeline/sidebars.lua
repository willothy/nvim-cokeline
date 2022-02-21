local rq_components = require("cokeline/components")

local str_rep = string.rep
local tbl_sort = table.sort

local vim_api = vim.api
local vim_map = vim.tbl_map

---@param sidebar  table
---@param winid  number
---@param default_hl  Hl
---@return Component[]
local get_sidebar_components = function(sidebar, winid, default_hl)
  local bufnr = vim_api.nvim_win_get_buf(winid)

  if vim.bo[bufnr].filetype ~= sidebar.filetype then
    return {}
  end

  -- This is kind of a hack but fuck it: `comp_to_component` expects a fully
  -- formed `buffer`, instead we pass a table with a single `number` key, since
  -- that's the only one actually used in that function.
  -- This works as long as all the fields of that component (`text`, `hl`, ..)
  -- are not in the form `function(buffer) -> T`.
  local components = vim_map(function(comp)
    return rq_components.comp_to_component(
      comp,
      default_hl,
      { number = bufnr }
    )
  end, rq_components.cmps_to_comps(sidebar.components))

  local rq_rendering = require("cokeline/rendering")

  local width_of_components = rq_rendering.get_width_of_components(components)
  local sidebar_width = vim_api.nvim_win_get_width(winid)

  if width_of_components > sidebar_width then
    tbl_sort(components, rq_rendering.sort_by_decreasing_priority)
    components = rq_rendering.trim_components(components, sidebar_width)
    tbl_sort(components, rq_rendering.sort_by_increasing_idx)
  elseif width_of_components < sidebar_width then
    local space_left = sidebar_width - width_of_components

    components[#components].text = components[#components].text
      .. str_rep(" ", space_left)

    components[#components].width = components[#components].width + space_left
  end

  return components
end

---@param offsets  table
---@param layout  table
---@return Component[], Component[]
local get_left_right_sidebar_components =
  function(left_sidebar, right_sidebar, default_hl, layout)
    -- If the first split level is not given by vertically split windows we
    -- return early.
    if layout[1] ~= "row" then
      return {}, {}
    end

    -- `layout[2]` is a nested list representing the tree of vertically split
    -- windows in a tabpage. For example, for a layout like
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
    local first_split, last_split = window_tree[1], window_tree[#window_tree]

    local left_sidebar_components = (first_split[1] == "leaf" and left_sidebar)
        and get_sidebar_components(
          left_sidebar,
          first_split[2],
          default_hl
        )
      or {}

    local right_sidebar_components = (
          last_split[1] == "leaf" and right_sidebar
        )
        and get_sidebar_components(
          right_sidebar,
          last_split[2],
          default_hl
        )
      or {}

    return left_sidebar_components, right_sidebar_components
  end

return {
  get_left_right_sidebar_components = get_left_right_sidebar_components,
}
