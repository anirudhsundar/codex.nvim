local M = {}

---Remove cached codex modules to allow fresh config per test.
function M.reset_modules()
  for name, _ in pairs(package.loaded) do
    if name:find("^codex") then
      package.loaded[name] = nil
    end
  end
end

---Create a temp buffer, run `fn`, then clean up.
---@param lines string[]
---@param fn fun(buf: integer)
function M.with_tmp_buf(lines, fn)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines or {})
  local prev = vim.api.nvim_get_current_buf()
  vim.api.nvim_set_current_buf(buf)
  pcall(fn, buf)
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
  end
  if vim.api.nvim_buf_is_valid(prev) then
    vim.api.nvim_set_current_buf(prev)
  end
end

---Stub diagnostics on a buffer.
---@param buf integer
---@param msg string
function M.add_diag(buf, msg)
  local ns = vim.api.nvim_create_namespace("codex_test")
  vim.diagnostic.set(ns, buf, {
    {
      lnum = 0,
      col = 0,
      end_lnum = 0,
      end_col = 1,
      message = msg or "oops",
      source = "codex_test",
    },
  })
end

---Set quickfix list entries.
---@param items table
function M.set_qflist(items)
  vim.fn.setqflist(items or {})
end

return M
