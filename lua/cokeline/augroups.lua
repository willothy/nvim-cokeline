local math_max = math.max
local math_min = math.min

local vim_fn = vim.fn
local vim_opt = vim.opt

local gl_settings

---@type Buffer[]
local gl_mut_valid_buffers

---@param buffers  Buffer[]
local set_valid_buffers = function(buffers)
  gl_mut_valid_buffers = buffers
end

local toggle = function()
  local listed_buffers = vim_fn.getbufinfo({buflisted = 1})
  vim_opt.showtabline = #listed_buffers > 0 and 2 or 0
end

---@param bufnr  number
local focus = function(bufnr)
  if #gl_mut_valid_buffers == 1 then return end

  local buffer_from_bufnr = function()
    for _, buffer in pairs(gl_mut_valid_buffers) do
      if buffer.number == bufnr then
        return buffer
      end
    end
  end

  local deleted_buffer = buffer_from_bufnr()
  if not deleted_buffer then return end

  ---@param buffer  Buffer
  ---@return Buffer
  local prev = function(buffer)
    if buffer._vidx == 1 then
      return gl_mut_valid_buffers[2]
    end
    return gl_mut_valid_buffers[math_max(1, buffer._vidx - 1)]
  end

  ---@param buffer  Buffer
  ---@return Buffer
  local next = function(buffer)
    local len = #gl_mut_valid_buffers
    if buffer._vidx == len then
      return gl_mut_valid_buffers[len - 1]
    end
    return gl_mut_valid_buffers[math_min(len, buffer._vidx + 1)]
  end

  vim.cmd(('b%s'):format(
    (gl_settings.focus_on_delete == 'prev' and prev(deleted_buffer).number)
    or (gl_settings.focus_on_delete == 'next' and next(deleted_buffer).number)
    or ''
  ))
end

local setup = function(settings)
  gl_settings = settings

  vim.cmd([[
  augroup cokeline_toggle
    autocmd VimEnter,BufAdd * lua require('cokeline/augroups').toggle()
  augroup END
  ]])

  if gl_settings.focus_on_delete then
    vim.cmd([[
    augroup cokeline_focus
      autocmd BufDelete *
        \ exe printf(
        \   'lua require("cokeline/augroups").focus(%s)', expand('<abuf>')
        \ )
    augroup END
    ]])
  end
end

return {
  set_valid_buffers = set_valid_buffers,
  toggle = toggle,
  focus = focus,
  setup = setup,
}
