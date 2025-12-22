local M = {}

---@class codex.api.prompt.Opts
---@field submit? boolean
---@field context? codex.Context

---Prompt codex by sending a new turn.
---@param prompt string
---@param opts? codex.api.prompt.Opts
function M.prompt(prompt, opts)
  local referenced_prompt = require("codex.config").opts.prompts[prompt]
  prompt = referenced_prompt and referenced_prompt.prompt or prompt
  opts = opts or {}
  opts.context = opts.context or require("codex.context").new()

  local rendered = opts.context:render(prompt)
  local plaintext = opts.context.plaintext(rendered.output)

  require("codex.session")
    .send_prompt(plaintext)
    :catch(function(err)
      vim.notify(tostring(err), vim.log.levels.ERROR, { title = "codex" })
    end)
    :next(function()
      opts.context:cleanup()
    end)
end

return M
