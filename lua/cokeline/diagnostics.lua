local M = {}

local diagnostics = vim.diagnostic or vim.lsp.diagnostic

function M.get_status(bufnr)
  local status = {
    errors = 0,
    warnings = 0,
    infos = 0,
    hints = 0,
  }

  for _, diagnostic in pairs(diagnostics.get(bufnr)) do
    if diagnostic.severity == 1 then
      status.errors = status.errors + 1

    elseif diagnostic.severity == 2 then
      status.warnings = status.warnings + 1

    elseif diagnostic.severity == 3 then
      status.infos = status.infos + 1

    elseif diagnostic.severity == 4 then
      status.hints = status.hints + 1
    end
  end

  return status
end

return M
