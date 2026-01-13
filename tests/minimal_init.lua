-- Minimal init for PlenaryBustedDirectory
vim.opt.runtimepath:append(".")

local cwd = vim.loop.cwd()

-- Lua paths for test helpers and plugin
package.path = table.concat({
  cwd .. "/?.lua",
  cwd .. "/?/init.lua",
  cwd .. "/tests/?.lua",
  package.path,
}, ";")

local function try_add(path)
  local stat = vim.loop.fs_stat(path)
  if stat then
    vim.opt.runtimepath:append(path)
    vim.opt.packpath:append(path)
    return true
  end
  return false
end

local roots = {
  cwd .. "/../plenary.nvim",
  cwd .. "/../../plenary.nvim",
  vim.fn.expand("$HOME/.vim/plugged/plenary.nvim"),
  vim.fn.stdpath("data") .. "/site/pack/packer/start/plenary.nvim",
  vim.fn.stdpath("data") .. "/lazy/plenary.nvim",
}
for _, p in ipairs(roots) do
  if try_add(p) then
    break
  end
end

vim.g.codex_opts = vim.g.codex_opts or {}

vim.cmd("runtime plugin/plenary.vim")
