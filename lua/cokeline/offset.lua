local rq_components = require('cokeline/components')

local str_rep = string.rep
local tbl_insert = table.insert

local vim_api = vim.api
local vim_fn = vim.fn
local vim_map = vim.tbl_map

---@param offsets  table
---@return Component[]
local get_sidebar_components = function(offsets)
  local layout = vim_fn.winlayout()

  -- If the .. return early.
  if layout[1] ~= 'row' then return {} end

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
  -- where each leaf is represented as `{'leaf', <winid>}`.
  local window_tree = layout[2]

  -- Since we're checking if we need to display a sidebar offsets we're only
  -- interested in the first and last window splits.
  local first, _ = window_tree[1], window_tree[#window_tree]

  -- If neither of those nodes is a leaf we just return early. For now let's
  -- just focus on the first split.
  if first[1] ~= 'leaf' then
  -- if first[1] ~= 'leaf' and last[1] ~= 'leaf' then
    return {}
  end

  local first_winid = first[2]
  local bufnr = vim_api.nvim_win_get_buf(first_winid)
  local filetype = vim.bo[bufnr].filetype

  local offset
  for _, o in ipairs(offsets) do
    if filetype == o.filetype then
      offset = o
    end
  end
  if not offset then return {} end

  local width = vim_api.nvim_win_get_width(first_winid)
  print(bufnr, filetype, width)

  local comps = rq_components.cmps_to_comps(offset.components)
  local components = vim_map(function(comp)
    return rq_components.comp_to_component(comp)
  end, comps)

  local rq_rendering = require('cokeline/rendering')
  local space_left = width - rq_rendering.get_width_of_components(components)
  print(space_left)
  if space_left > 0 then
    local comp = rq_components.cmps_to_comps({{
        text = str_rep(' ', space_left)
    }})[1]
    tbl_insert(components, rq_components.comp_to_component(comp))
  end

  return components
end

return {
  get_sidebar_components = get_sidebar_components,
}
