local M = {}

function M.on_save()
  local files = {}
  for entry in require("cokeline.history"):iter() do
    table.insert(files, entry.path)
  end
  return files
end

function M.on_post_load(data)
  local history = require("cokeline.history")
  for _, path in ipairs(data) do
    local buf = vim.fn.bufnr(path)
    if buf then
      history:push(buf)
    end
  end
end

return M
