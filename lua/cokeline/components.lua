local rq_hlgroups = require("cokeline/hlgroups")

local str_rep = string.rep
local tbl_concat = table.concat
local tbl_insert = table.insert

local vim_fn = vim.fn
local vim_map = vim.tbl_map

local gl_continuation_fmts = {
  edges = {
    left = " …%s",
    right = "%s… ",
  },
  buffers = {
    left = "…%s",
    middle = "%s…%s",
    right = "%s…",
  },
}

---@diagnostic disable: duplicate-doc-class

---@class Cmp
---@field text  string | fun(buffer: Buffer): string
---@field hl  Hl | nil
---@field delete_buffer_on_left_click  boolean | nil
---@field truncation  table | nil

---@class Comp
---@field text  string | fun(buffer: Buffer): string
---@field hl  Hl | nil
---@field delete_buffer_on_left_click  boolean
---@field truncation  table
---@field idx  number

---@class Component
---@field text  string
---@field hlgroup  Hlgroup
---@field delete_buffer_on_left_click  boolean
---@field truncation  table
---@field idx  number
---@field bufnr  bufnr
---@field width  number

---@param cmp  Cmp
---@param idx  number
---@return Comp
local cmp_to_comp = function(cmp, idx)
  local text = cmp.text
  local hl = cmp.hl
  local delete_buffer_on_left_click = cmp.delete_buffer_on_left_click or false
  local priority = cmp.truncation and cmp.truncation.priority or idx
  local direction = cmp.truncation and cmp.truncation.direction or "right"

  return {
    text = text,
    hl = hl,
    delete_buffer_on_left_click = delete_buffer_on_left_click,
    truncation = {
      priority = priority,
      direction = direction,
    },
    idx = idx,
  }
end

---@param cmps  Cmp[]
---@return Comp[]
local cmps_to_comps = function(cmps)
  local comps = {}
  for i, cmp in ipairs(cmps) do
    tbl_insert(comps, cmp_to_comp(cmp, i))
  end
  return comps
end

---@param comp  Comp
---@param default_hl  Hl
---@param buffer  Buffer
---@return Component
local comp_to_component = function(comp, default_hl, buffer)
  ---@param field  string | hexcolor | attr | fun()
  ---@return string | hexcolor | attr
  local evaluate_field = function(field)
    return (type(field) == "string" and field)
      or (type(field) == "function" and field(buffer))
  end

  local text = evaluate_field(comp.text)

  local width = vim_fn.strwidth(text)

  local bufnr = buffer.number

  local hlgroup_name = ("cokeline_buffer_%s_component_%s"):format(
    bufnr,
    comp.idx
  )

  local guifg = comp.hl and comp.hl.fg and evaluate_field(comp.hl.fg)
    or evaluate_field(default_hl.fg)

  local guibg = comp.hl and comp.hl.bg and evaluate_field(comp.hl.bg)
    or evaluate_field(default_hl.bg)

  local gui = comp.hl and comp.hl.style and evaluate_field(comp.hl.style)
    or evaluate_field(default_hl.style)

  local hlgroup = rq_hlgroups.new_hlgroup(hlgroup_name, guifg, guibg, gui)

  return {
    text = text,
    hlgroup = hlgroup,
    delete_buffer_on_left_click = comp.delete_buffer_on_left_click,
    truncation = comp.truncation,
    idx = comp.idx,
    bufnr = bufnr,
    width = width,
  }
end

---Takes in a `component`, returns a new component given by shortening the
---`component`'s text to `available_space` characters in the given
---`direction`. If a direction is not given it uses the
---`component.truncation.direction` field instead.
---@param component  Component
---@param available_space  number
---@param direction  '"left"' | '"right"' | nil
---@return Component
local shorten_component = function(component, available_space, direction)
  local continuation_fmt = direction and gl_continuation_fmts.edges[direction]
    or gl_continuation_fmts.buffers[component.truncation.direction]

  direction = direction or component.truncation.direction
  local text

  if direction ~= "middle" then
    local net_available_space = available_space
      - vim_fn.strwidth(continuation_fmt:format(""))

    local start_char = (direction or component.truncation.direction) == "left"
        and component.width - net_available_space
      or 0

    local cut_text = vim_fn.strcharpart(
      component.text,
      start_char,
      net_available_space
    )

    text = vim_fn.strwidth(cut_text) == net_available_space
        and continuation_fmt:format(cut_text)
      or continuation_fmt:format(str_rep(" ", net_available_space))
  else
    local net_available_space = available_space
      - vim_fn.strwidth(continuation_fmt:format("", ""))

    local space_left = math.floor(net_available_space / 2)
    local space_right = space_left + net_available_space % 2

    local text_left = vim_fn.strcharpart(component.text, 0, space_left)
    local text_right = vim_fn.strcharpart(
      component.text,
      component.width - space_right,
      space_right
    )

    text = continuation_fmt:format(text_left, text_right)
  end

  local width = vim_fn.strwidth(text)

  return {
    text = text,
    hlgroup = component.hlgroup,
    delete_buffer_on_left_click = component.delete_buffer_on_left_click,
    truncation = component.truncation,
    width = width,
    bufnr = component.bufnr,
    idx = component.idx,
  }
end

---Takes in a component, returns its rendered string.
---@param component  Component
---@return string
local render_component = function(component)
  local text = rq_hlgroups.embed_in_hlgroup(component.hlgroup, component.text)
  if not vim_fn.has("tablineat") then
    return text
  end
  local bufnr = component.bufnr
  return component.delete_buffer_on_left_click
      and ("%%%s@cokeline#handle_close_button_click@%s%%X"):format(
        bufnr,
        text
      )
    or ("%%%s@cokeline#handle_click@%s%%X"):format(bufnr, text)
end

---Takes in a list of components, returns the concatnation of their rendered
---strings.
---@param components  Component[]
---@return string
local render_components = function(components)
  return tbl_concat(vim_map(function(component)
    return render_component(component)
  end, components))
end

return {
  gl_continuation_fmts = gl_continuation_fmts,
  cmps_to_comps = cmps_to_comps,
  comp_to_component = comp_to_component,
  shorten_component = shorten_component,
  render_components = render_components,
}
