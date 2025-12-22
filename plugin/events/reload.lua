vim.api.nvim_create_autocmd("User", {
  group = vim.api.nvim_create_augroup("CodexReload", { clear = true }),
  pattern = "CodexEvent:item/completed",
  callback = function(args)
    local params = args.data and args.data.params or {}
    local item = params.item
    if item and item.type == "fileChange" then
      if not vim.o.autoread then
        vim.notify(
          "Please set `vim.o.autoread = true` to reload files edited by codex automatically",
          vim.log.levels.WARN,
          { title = "codex" }
        )
        return
      end
      vim.schedule(function()
        vim.cmd("checktime")
      end)
    end
  end,
  desc = "Reload buffers edited by codex",
})
