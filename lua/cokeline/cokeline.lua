local renderers = require('cokeline/renderers')

local insert = table.insert

local M = {}

local centered_index

M.Cokeline = {}

function M.Cokeline:new()
  local cokeline = {
    before = '',
    main = '',
    after = '',
    lines = {},
  }
  setmetatable(cokeline, self)
  self.__index = self
  return cokeline
end

function M.Cokeline:add_line(line)
  if line.buffer.is_focused then
    centered_index = line.buffer.index
  end
  insert(self.lines, line)
end

-- TODO: refactor all this function.
function M.Cokeline:render(settings)
  -- 3 buffers, first 2 are visible, last one isn't. We focus the last buffer,
  -- then the 2nd, then close the 2nd. Without this check centered_index would
  -- still be 2, which would cause centered_line to be nil.
  while true do
    if self.lines[centered_index] then
      break
    end
    centered_index = centered_index - 1
  end

  local lines = {
    left = {},
    center = nil,
    right = {},
    width = {
      left = 0,
      right = 0,
    },
  }

  for i, line in ipairs(self.lines) do
    if settings.min_line_width and (line.width < settings.min_line_width) then
      line = line:expand({available_space = settings.min_line_width})
    elseif settings.max_line_width and (line.width > settings.max_line_width) then
      line = line:shorten({available_space = settings.max_line_width})
    end

    if i < centered_index then
      insert(lines.left, line)
      lines.width.left = lines.width.left + line.width
    elseif i == centered_index then
      lines.center = line
    elseif i > centered_index then
      insert(lines.right, line)
      lines.width.right = lines.width.right + line.width
    end
  end

  local available_space = vim.o.columns

  self.main = renderers.default(lines, available_space)
end

return M
