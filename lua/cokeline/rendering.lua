local rq_components = require("cokeline/components")
local rq_sidebars = require("cokeline/sidebars")

local tbl_insert = table.insert
local tbl_remove = table.remove
local tbl_sort = table.sort
local tbl_unpack = unpack or table.unpack

local vim_filter = vim.tbl_filter
local vim_fn = vim.fn
local vim_list_extend = vim.list_extend
local vim_opt = vim.opt

local gl_comps, gl_default_hls, gl_settings

---@type index
local gl_mut_current_buffer_index

---@param buffers  Buffer[]
---@param previous_buffer_index  index
---@return Buffer
local find_current_buffer = function(buffers, previous_buffer_index)
  local focused_buffer = vim_filter(function(buffer)
    return buffer.is_focused
  end, buffers)[1]

  return focused_buffer or buffers[previous_buffer_index] or buffers[#buffers]
end

---@param components  Component[]
---@return number
local get_width_of_components = function(components)
  local width_of_components = 0
  for _, component in pairs(components) do
    width_of_components = width_of_components + component.width
  end
  return width_of_components
end

---@param comp1  Comp
---@param comp2  Comp
---@return boolean
local sort_by_decreasing_priority = function(comp1, comp2)
  return comp1.truncation.priority < comp2.truncation.priority
end

---@param comp1  Comp
---@param comp2  Comp
---@return boolean
local sort_by_increasing_idx = function(comp1, comp2)
  return comp1.idx < comp2.idx
end

---Takes in a list of components, a number of characters given by
---`available_space` and an optional 'left' or 'right' `direction`, returns a
---new list of components `available_space` wide obtained by trimming
---the original `components` in the given direction.
---@param components  Component[]
---@param available_space  number
---@param direction  '"left"' | '"right"' | nil
---@return Component[]
local trim_components = function(components, available_space, direction)
  local width_of_components = get_width_of_components(components)

  local continuation_fmt_width = vim_fn.strwidth(
    rq_components.gl_continuation_fmts[direction and "edges" or "buffers"].left:format(
      ""
    )
  ) -- aka 1

  local next = direction == "left" and function(_)
    return 1
  end or function(i)
    return i - 1
  end

  local prev = direction == "left" and function(_)
    return 1
  end or function(i)
    return i + 1
  end

  local i = direction == "left" and 1 or #components
  local last_removed_component
  while
    (width_of_components > available_space)
    or (
      components[i].width + available_space - width_of_components
      < continuation_fmt_width
    )
  do
    width_of_components = width_of_components - components[i].width
    last_removed_component = tbl_remove(components, i)
    i = next(i)
    if #components == 0 then
      break
    end
  end

  if
    (continuation_fmt_width < available_space - width_of_components)
    or #components == 0
  then
    tbl_insert(
      components,
      prev(i),
      rq_components.shorten_component(
        last_removed_component,
        available_space - width_of_components,
        direction
      )
    )
  else
    components[i] = rq_components.shorten_component(
      components[i],
      components[i].width + available_space - width_of_components,
      direction
    )
  end

  return components
end

---Takes in a buffer and returns a list of all its components plus their total
---combined width.
---@param buffer  Buffer
---@return Component[], number
local buffer_to_components = function(buffer)
  local hl = gl_default_hls[buffer.is_focused and "focused" or "unfocused"]
  local components = {}
  for _, comp in ipairs(gl_comps) do
    local component = rq_components.comp_to_component(comp, hl, buffer)
    if component.width > 0 then
      tbl_insert(components, component)
    end
  end

  local width_of_components = get_width_of_components(components)

  if width_of_components <= gl_settings.max_buffer_width then
    return components, width_of_components
  else
    tbl_sort(components, sort_by_decreasing_priority)
    components = trim_components(components, gl_settings.max_buffer_width)
    tbl_sort(components, sort_by_increasing_idx)
    return components, gl_settings.max_buffer_width
  end
end

---Takes in a list of buffers and returns a list of all their components plus
---their total combined width.
---@param buffers  Buffer[]
---@return Component[], number
local buffers_to_components = function(buffers)
  local components = {}
  local width_of_components = 0
  for _, buffer in ipairs(buffers) do
    local buffer_components, width = buffer_to_components(buffer)
    width_of_components = width_of_components + width
    for _, component in ipairs(buffer_components) do
      tbl_insert(components, component)
    end
  end
  return components, width_of_components
end

---This is the main function responsible for rendering the bufferline. It takes
---the list of visible buffers, figures out which components to display and
---returns their rendered version.
---@param visible_buffers  Buffer[]
---@return string
local render = function(visible_buffers)
  -- Pipeline in pseudo F# syntax is:
  -- check_if_sidebars_need_to_be_displayed
  -- >> get_available_space
  -- >> find_current_buffer
  -- >> check_if_current_buffer_alone_fits
  -- >> render_all_buffers_{left,right}_of_current
  -- >> get_available_space_{left,right}_of_current_buffer
  -- >> check_if_buffers_{left,right}_of_current_need_to_be_trimmed
  -- >> render_components

  -- Get left and right sidebar components.
  local left_sidebar_components, right_sidebar_components =
    (gl_settings.left_sidebar or gl_settings.right_sidebar)
        and rq_sidebars.get_left_right_sidebar_components(
          gl_settings.left_sidebar,
          gl_settings.right_sidebar,
          gl_default_hls,
          vim_fn.winlayout()
        )
      or {},
    {}

  -- Compute available space for the buffer components.
  local available_space = vim_opt.columns._value
    - get_width_of_components(left_sidebar_components)
    - get_width_of_components(right_sidebar_components)

  local current_buffer = find_current_buffer(
    visible_buffers,
    gl_mut_current_buffer_index
  )
  gl_mut_current_buffer_index = current_buffer.index

  local components_of_current, width_of_current = buffer_to_components(
    current_buffer
  )

  if width_of_current >= available_space then
    if #visible_buffers == 1 then
      components_of_current = trim_components(
        components_of_current,
        available_space
      )
    end
    if current_buffer.index > 1 then
      components_of_current = trim_components(
        components_of_current,
        available_space,
        "left"
      )
    end
    if current_buffer.index < #visible_buffers then
      components_of_current = trim_components(
        components_of_current,
        available_space,
        "right"
      )
    end
    return rq_components.render_components(left_sidebar_components)
      .. rq_components.render_components(components_of_current)
      .. rq_components.render_components(right_sidebar_components)
  end

  local components_left_of_current, width_left_of_current =
    buffers_to_components({
      tbl_unpack(visible_buffers, 1, current_buffer.index - 1),
    })

  local components_right_of_current, width_right_of_current =
    buffers_to_components({
      tbl_unpack(visible_buffers, current_buffer.index + 1, #visible_buffers),
    })

  local components = vim_list_extend(
    vim_list_extend(components_left_of_current, components_of_current),
    components_right_of_current
  )

  local available_space_left, available_space_right = gl_settings.slider(
    available_space - width_of_current,
    width_left_of_current,
    width_right_of_current
  )

  if width_left_of_current > available_space_left then
    components = trim_components(
      components,
      available_space_left + width_of_current + width_right_of_current,
      "left"
    )
  end

  if width_right_of_current > available_space_right then
    components = trim_components(components, available_space, "right")
  end

  return rq_components.render_components(left_sidebar_components)
    .. rq_components.render_components(components)
    .. rq_components.render_components(right_sidebar_components)
end

---@param settings  table
---@param default_hl  table
---@param comps  Comp[]
local setup = function(settings, default_hl, comps)
  gl_settings = settings
  gl_default_hls = default_hl
  gl_comps = comps
end

return {
  sort_by_decreasing_priority = sort_by_decreasing_priority,
  sort_by_increasing_idx = sort_by_increasing_idx,
  trim_components = trim_components,
  get_width_of_components = get_width_of_components,
  render = render,
  setup = setup,
}
