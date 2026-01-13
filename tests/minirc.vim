set nocompatible
set runtimepath^=.

" Try to add plenary.nvim to runtimepath
lua << EOF
package.path = vim.fn.getcwd() .. "/?.lua;" .. vim.fn.getcwd() .. "/?/init.lua;" .. package.path
package.path = vim.fn.getcwd() .. "/tests/?.lua;" .. package.path
local uv = vim.loop
local function add(path)
  if path and uv.fs_stat(path) then
    vim.opt.rtp:append(path)
    vim.opt.packpath:append(path)
    return true
  end
  return false
end

local roots = {
  vim.fn.getcwd() .. "/../plenary.nvim",
  vim.fn.getcwd() .. "/../../plenary.nvim",
  vim.fn.expand("$HOME/.vim/plugged/plenary.nvim"),
  vim.fn.stdpath("data") .. "/site/pack/packer/start/plenary.nvim",
  vim.fn.stdpath("data") .. "/lazy/plenary.nvim",
}
for _, p in ipairs(roots) do
  if add(p) then
    break
  end
end
EOF

runtime plugin/plenary.vim

lua << EOF
local function busted_dir(dir)
  dir = dir ~= "" and dir or "tests"
  require("plenary.test_harness").test_directory(dir, { minimal_init = "tests/minimal_init.lua" })
end
vim.api.nvim_create_user_command("PlenaryBustedDirectory", function(opts)
  busted_dir(table.concat(opts.fargs, " "))
end, { nargs = "?", complete = "dir" })
EOF

lua << EOF
vim.cmd("syntax off")
vim.g.codex_opts = vim.g.codex_opts or {}
EOF
