---`codex.nvim` public API.
local M = {}

M.ask = require("codex.ui.ask").ask
M.select = require("codex.ui.select").select

M.prompt = require("codex.api.prompt").prompt
M.operator = require("codex.api.operator").operator
M.command = require("codex.api.command").command

M.toggle = require("codex.connection").toggle
M.start = require("codex.connection").start
M.stop = require("codex.connection").stop
M.toggle_output_details = require("codex.output").toggle_details

M.statusline = require("codex.status").statusline

return M
