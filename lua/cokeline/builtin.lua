local M = {}

M.time = function()
  local hour = os.date("%I"):gsub("0(%d)", "%1")
  local minute = os.date("%M")

  return hour .. ":" .. minute
end

return M
