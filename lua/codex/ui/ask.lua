---@module 'snacks.input'

local M = {}

---@class codex.ask.Opts
---@field prompt? string
---@field blink_cmp_sources? string[]
---@field snacks? table

---Input a prompt for codex.
---@param default? string
---@param opts? codex.api.prompt.Opts
function M.ask(default, opts)
  opts = opts or {}
  opts.context = opts.context or require("codex.context").new()

  ---@type snacks.input.Opts
  local input_opts = {
    default = default,
    highlight = function(text)
      local rendered = opts.context:render(text)
      return vim.tbl_map(function(extmark)
        return { extmark.col, extmark.end_col, extmark.hl_group }
      end, opts.context.extmarks(rendered.input))
    end,
    completion = "customlist,v:lua.codex_completion",
    win = {
      b = { completion = true },
      bo = { filetype = "codex_ask" },
      on_buf = function(win)
        vim.api.nvim_create_autocmd("InsertEnter", {
          once = true,
          buffer = win.buf,
          callback = function()
            if package.loaded["blink.cmp"] then
              require("codex.cmp.blink").setup(require("codex.config").opts.ask.blink_cmp_sources)
            end
          end,
        })
      end,
    },
  }

  input_opts = vim.tbl_deep_extend("force", input_opts, require("codex.config").opts.ask)
  input_opts = vim.tbl_deep_extend("force", input_opts, require("codex.config").opts.ask.snacks or {})

  require("codex.cmp.blink").context = opts.context

  vim.ui.input(input_opts, function(value)
    opts.context:cleanup()

    if value and value ~= "" then
      require("codex").prompt(value, opts)
    end
  end)
end

---Completion for context placeholders.
---@param _ string
---@param CmdLine string
---@param _ number
---@return table<string>
_G.codex_completion = function(_, CmdLine, _)
  local start_idx, end_idx = CmdLine:find("([^%s]+)$")
  local latest_word = start_idx and CmdLine:sub(start_idx, end_idx) or nil

  local completions = {}
  for placeholder, _ in pairs(require("codex.config").opts.contexts) do
    table.insert(completions, placeholder)
  end

  local items = {}
  for _, completion in pairs(completions) do
    if not latest_word then
      table.insert(items, CmdLine .. completion)
    elseif completion:find(latest_word, 1, true) == 1 then
      local new_cmd = CmdLine:sub(1, start_idx - 1) .. completion .. CmdLine:sub(end_idx + 1)
      table.insert(items, new_cmd)
    end
  end
  return items
end

return M
