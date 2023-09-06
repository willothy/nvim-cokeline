local M = {}

M.tab_cache = {}

M.tab_lookup = {}

M.valid_lookup = {}

M.visible_buffers = {}

M.valid_buffers = {}

---@type Component<Buffer>[]
M.components = {}

---@type Component<RhsContext>[]
M.rhs = {}

---@type Component<SidebarContext>[]
M.sidebar = {}

---@type Component<TabPage>[]
M.tabs = {}

return M
