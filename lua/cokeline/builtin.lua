local M = {}

M.time = function()
  local hour = os.date("%I"):gsub("0(%d)", "%1")
  local minute = os.date("%M")
  local ampm = os.date("%p")

  return string.format("%s:%s %s", hour, minute, ampm)
end

return M
