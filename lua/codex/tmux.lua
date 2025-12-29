local M = {}

---@class codex.tmux_resume.Opts
---@field enabled boolean
---@field window_name? string

local function in_tmux()
  return vim.env.TMUX ~= nil and vim.env.TMUX ~= ""
end

---Open a tmux window running `codex resume <thread_id>`, auto-closing on exit.
function M.resume_thread_in_tmux()
  local opts = require("codex.config").opts.tmux_resume or {}
  if not opts.enabled then
    vim.notify("tmux resume helper is disabled (enable tmux_resume.enabled)", vim.log.levels.WARN, { title = "codex" })
    return
  end
  if not in_tmux() then
    vim.notify("Not in a tmux session; cannot open codex window", vim.log.levels.WARN, { title = "codex" })
    return
  end

  local status = require("codex.session").status()
  if not status.thread_id then
    vim.notify("No codex thread yet; ask a question first", vim.log.levels.WARN, { title = "codex" })
    return
  end

  local window_name = opts.window_name or "codex-thread"
  local cmd = string.format(
    'tmux new-window -P -F "#W" -n %s \'thread_id=%s; codex resume "$thread_id"; WIN=$(tmux display-message -p "#{window_id}"); tmux kill-window -t "$WIN"\'',
    vim.fn.shellescape(window_name),
    vim.fn.shellescape(status.thread_id)
  )

  local ok = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to open tmux window: " .. tostring(ok), vim.log.levels.ERROR, { title = "codex" })
    return
  end
  vim.notify("Opened tmux window for codex resume: " .. status.thread_id, vim.log.levels.INFO, { title = "codex" })
end

return M
