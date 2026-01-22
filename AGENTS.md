# Repository Guidelines

## Project Structure & Module Organization
- `lua/codex/`: core plugin modules (JSON-RPC connection/session/output, context, api/ui helpers, status, config).
- `plugin/`: autocommands and integration hooks.
- `doc/`: user docs (`codex.txt`, `codex-integration.txt` for JSON-RPC details).
- `tests/`: Plenary specs, helpers, minimal init files; `tests/run_tests.sh` to run everything.
- Keep AGENTS.md updated whenever workflows or directories change.

## Build, Test, and Development Commands
- No build step; Lua files are loaded directly by Neovim.
- Run tests (requires `plenary.nvim` on `rtp`):  
  `./tests/run_tests.sh`  
  or  
  `nvim --headless -u tests/minirc.vim -c "lua require('plenary.test_harness').test_directory('tests', { minimal_init = 'tests/minimal_init.lua' })" -c qa`

## Coding Style & Naming Conventions
- Lua: 2-space indent; ASCII unless existing code uses icons.
- Module naming: `codex.*` under `lua/codex/`.
- Comments only where logic is non-obvious; avoid trailing whitespace.

## Testing Guidelines
- Framework: Plenary + Busted; specs end with `_spec.lua` in `tests/`.
- Helpers: `codex_test_helpers` for buffers/diagnostics/quickfix/module reset.
- Prefer mocks; do not spawn the real `codex` binary in unit tests.
- Minimal init for tests: `tests/minimal_init.lua` (sets rtp/packpath/package.path).

## Commit & Pull Request Guidelines
- Commits: imperative, scoped (e.g., `add context placeholder docs`, `fix output buffer newline`).
- PRs: include change summary, testing done (`./tests/run_tests.sh`), and screenshots/notes for user-facing changes.

## Security & Configuration Tips
- The plugin shells out to `codex app-server`; ensure `codex` is on `PATH`.
- Keep JSON-RPC interactions local; avoid adding networked side-effects in tests.
- Update docs/tests when adding placeholders/prompts or altering JSON-RPC flows (see `doc/codex-integration.txt`).
