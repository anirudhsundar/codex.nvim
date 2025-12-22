vim.api.nvim_create_autocmd("VimLeave", {
  group = vim.api.nvim_create_augroup("CodexConnection", { clear = true }),
  pattern = "*",
  callback = function()
    pcall(require("codex.connection").stop)
  end,
  desc = "Stop codex app-server on exit",
})
