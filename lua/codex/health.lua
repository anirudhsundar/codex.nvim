local M = {}

function M.check()
  vim.health.start("codex.nvim")

  vim.health.ok("`nvim` version: `" .. tostring(vim.version()) .. "`.")

  local plugin_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h")
  local git_hash = vim.fn.system("cd " .. vim.fn.shellescape(plugin_dir) .. " && git rev-parse HEAD")
  if vim.v.shell_error == 0 then
    git_hash = vim.trim(git_hash)
    vim.health.ok("`codex.nvim` git commit hash: `" .. git_hash .. "`.")
  else
    vim.health.warn("Could not determine `codex.nvim` git commit hash.")
  end

  vim.health.ok("`vim.g.codex_opts`: " .. (vim.g.codex_opts and vim.inspect(vim.g.codex_opts) or "`nil`"))

  vim.health.start("codex.nvim [binaries]")
  if vim.fn.executable("codex") == 1 then
    local found_version = vim.fn.system("codex --version")
    found_version = vim.trim(vim.split(found_version, "\n")[1])
    vim.health.ok("`codex` available with version `" .. found_version .. "`.")
  else
    vim.health.error("`codex` executable not found in `$PATH`.", {
      "Install `codex` and ensure it's in your `$PATH`.",
    })
  end

  vim.health.start("codex.nvim [snacks]")
  local snacks_ok, snacks = pcall(require, "snacks")
  ---@cast snacks Snacks
  if snacks_ok then
    if snacks.config.get("input", {}).enabled then
      vim.health.ok("`snacks.input` is enabled: `ask()` will be enhanced.")
      local blink_ok = pcall(require, "blink.cmp")
      if blink_ok then
        vim.health.ok("`blink.cmp` is available: `opts.ask.blink_cmp_sources` will be registered in `ask()`.")
      end
    else
      vim.health.warn("`snacks.input` is disabled: `ask()` will not be enhanced.")
    end
    if snacks.config.get("picker", {}).enabled then
      vim.health.ok("`snacks.picker` is enabled: `select()` will be enhanced.")
    else
      vim.health.warn("`snacks.picker` is disabled: `select()` will not be enhanced.")
    end
  else
    vim.health.warn("`snacks.nvim` is not available: `ask()` and `select()` will not be enhanced.")
  end
end

return M
