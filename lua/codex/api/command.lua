local M = {}

local commands = {
  ["turn.interrupt"] = function()
    require("codex.session").interrupt()
  end,
  ["thread.new"] = function()
    require("codex.session").new_thread()
  end,
  ["thread.id"] = function()
    local status = require("codex.session").status()
    local msg = status.thread_id and ("Current Codex thread: " .. status.thread_id) or "No Codex thread started yet"
    vim.notify(msg, vim.log.levels.INFO, { title = "codex" })
  end,
  ["thread.tmux_resume"] = function()
    require("codex.tmux").resume_thread_in_tmux()
  end,
  ["thread.resume"] = function()
    vim.ui.input({ prompt = "Codex thread id to resume: " }, function(value)
      if value and value ~= "" then
        require("codex.session").resume_thread(value)
      end
    end)
  end,
}

---@param command string
function M.command(command)
  local handler = commands[command]
  if handler then
    handler()
  else
    vim.notify("Unknown codex command: " .. tostring(command), vim.log.levels.WARN, { title = "codex" })
  end
end

return M
