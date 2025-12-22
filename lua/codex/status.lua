local M = {}

local icons = {
  idle = "󰚩",
  running = "󱜙",
  error = "󱚡",
  disconnected = "󱚧",
}

function M.statusline()
  local connected = require("codex.connection").is_ready()
  if not connected then
    return icons.disconnected
  end

  local status = require("codex.session").status().turn_status
  if status == "inProgress" or status == "starting" then
    return icons.running
  elseif status == "failed" then
    return icons.error
  else
    return icons.idle
  end
end

return M
