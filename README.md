# codex.nvim

Neovim integration for the [`codex`](https://github.com/openai/codex) CLI. Launches the Codex app-server in the background, sends prompts with editor context, streams responses into a split, surfaces approval requests, and reloads files that Codex edits.

## ✨ Features

- Starts the Codex app-server on demand.
- Ask/Prompt helpers with contextual placeholders (`@this`, `@buffer`, `@diagnostics`, …).
- Simple output pane that streams Codex turns and tool output.
- Handles command/file change approvals inside Neovim.
- Reloads buffers touched by Codex.
- Statusline component for quick state checks.

## 📦 Setup

`codex` must be on your `$PATH` (run `codex --version` to verify).

### lazy.nvim

```lua
{
  dir = "anirudhsundar/codex.nvim",
  config = function()
    ---@type codex.Opts
    vim.g.codex_opts = {
      -- See lua/codex/config.lua for all options.
    }

    vim.o.autoread = true

    vim.keymap.set({ "n", "x" }, "<C-a>", function() require("codex").ask("@this: ", { submit = true }) end,
      { desc = "Ask codex" })
    vim.keymap.set({ "n", "x" }, "<C-x>", function() require("codex").select() end,
      { desc = "Execute codex action…" })
  end,
}
```

### vim-plug

```vim
call plug#begin()
Plug 'anirudhsundar/codex.nvim'
call plug#end()

" Optional config
let g:codex_opts = {}
let &autoread = 1
nnoremap <C-a> :lua require("codex").ask("@this: ", { submit = true })<CR>
xnoremap <C-a> :lua require("codex").ask("@this: ", { submit = true })<CR>
nnoremap <C-x> :lua require("codex").select()<CR>
```

After loading, run `:checkhealth codex` to verify the binary is available.

## 🚀 Usage

- `require("codex").ask(default?, opts?)` — open an input with context highlighting and send to Codex.
- `require("codex").prompt(prompt, opts?)` — resolve configured prompts and send immediately.
- `require("codex").select(opts?)` — quick picker for prompts/commands.
- `require("codex").operator(prompt, opts?)` — operator pending wrapper for motions/visual ranges.
- `require("codex").command(name)` — control helpers (`turn.interrupt`, `thread.new`).
- `require("codex").toggle_output_details()` — toggle between final-reply-only view (default) and full streamed details.
- `require("codex").statusline()` — statusline component.

Codex approvals appear as `vim.ui.select` prompts. File edits trigger `:checktime` when `vim.o.autoread` is set.

## ⚙️ Configuration

All defaults live in `lua/codex/config.lua`. Key options:

- `cmd` — command used to start the app-server (default `codex app-server`).
- `contexts` — functions that populate placeholders like `@this`.
- `prompts` — reusable prompts shown in `select()`.
- `output` — control the streaming pane (`width`, `auto_open`).
  - `show_details` — when `false` (default) only the final reply renders as markdown; toggle at runtime with `require("codex").toggle_output_details()`.

Disable or override any prompt/context by setting it to `false` in `vim.g.codex_opts`.

## 🙏 Notes

This plugin talks directly to the Codex app-server over JSON-RPC (stdio). It intentionally keeps the UI light while retaining the familiar prompt helpers from the original workflow.

## Acknowledgements

Thanks to [opencode.nvim](https://github.com/NickvanDyke/opencode.nvim) for inspiration on how to design a Neovim plugin for AI coding assistants!
