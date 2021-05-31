local format = string.format
local vimmap = vim.api.nvim_set_keymap

local M = {}

local Mapping = {
  lhs = '',
  rhs = '',
}

function Mapping:exec()
  vimmap('n', self.lhs, self.rhs, {noremap = true, silent = true})
end

function Mapping:new(lhs, rhs)
  mapping = {}
  setmetatable(mapping, self)
  self.__index = self
  if lhs then
    mapping.lhs = lhs
  end
  if rhs then
    mapping.rhs = rhs
  end
  mapping:exec()
  return mapping
end

function M.setup(settings)
  -- FIXME
  local strict_cycling = settings.cycle_prev_next_mappings

  Mapping:new(
    '<Plug>(cokeline-focus-prev)',
    format(
      ':call cokeline#focus_cycle(bufnr("%%"), -1, %s)<CR>',
      strict_cycling
    )
  )
  Mapping:new(
    '<Plug>(cokeline-focus-next)',
    format(
      ':call cokeline#focus_cycle(bufnr("%%"), 1, %s)<CR>',
      strict_cycling
    )
  )

  Mapping:new(
    '<Plug>(cokeline-switch-prev)',
    format(
      ':lua require"cokeline".switch({bufnr = vim.fn.bufnr("%%"), step = -1, strict_cycling = %s})<CR>',
      strict_cycling
    )
  )
  Mapping:new(
    '<Plug>(cokeline-switch-next)',
    format(
      ':lua require"cokeline".switch({bufnr = vim.fn.bufnr("%%"), step = 1, strict_cycling = %s})<CR>',
      strict_cycling
    )
  )

  for index = 1,settings.max_mapped_buffers do
    Mapping:new(
      format('<Plug>(cokeline-focus-%s)', index),
      format(':call cokeline#focus(%s)<CR>', index)
    )

    Mapping:new(
      format('<Plug>(cokeline-switch-%s)', index),
      format(
        ':lua require"cokeline".switch({bufnr = vim.fn.bufnr("%%"), target = %s, strict_cycling = %s})<CR>',
        index,
        strict_cycling
      )
    )
  end
  --
end

return M
