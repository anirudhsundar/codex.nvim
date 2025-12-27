local M = {}

---User configuration is read from `vim.g.codex_opts` for fast startup.
---@type codex.Opts|nil
vim.g.codex_opts = vim.g.codex_opts

---@class codex.output.Opts
---@field width? number Window width when auto opening the output
---@field auto_open? boolean Open the output window automatically
---@field show_details? boolean Show full streamed output instead of final reply only
---@field append_history? boolean Append new turns to the output buffer (default: true)

---@class codex.ask.Opts
---@field prompt? string
---@field blink_cmp_sources? string[]
---@field snacks? table

---@class codex.select.sections.Opts
---@field prompts? boolean
---@field commands? table<string, string>|false

---@class codex.select.Opts
---@field prompt? string
---@field sections? codex.select.sections.Opts
---@field snacks? table

---@class codex.Prompt : codex.api.prompt.Opts
---@field prompt string
---@field ask? boolean

---@class codex.Opts
---@field cmd? string Command to start the codex app-server
---@field sandbox? table Sandbox policy passed to `thread/start`
---@field contexts? table<string, fun(context: codex.Context): string|nil>
---@field prompts? table<string, codex.Prompt>
---@field ask? codex.ask.Opts
---@field select? codex.select.Opts
---@field output? codex.output.Opts

local defaults = {
  cmd = "codex app-server",
  sandbox = nil,
  -- stylua: ignore
  contexts = {
    ["@this"] = function(context) return context:this() end,
    ["@buffer"] = function(context) return context:buffer() end,
    ["@buffers"] = function(context) return context:buffers() end,
    ["@visible"] = function(context) return context:visible_text() end,
    ["@diagnostics"] = function(context) return context:diagnostics() end,
    ["@quickfix"] = function(context) return context:quickfix() end,
    ["@diff"] = function(context) return context:git_diff() end,
    ["@grapple"] = function(context) return context:grapple_tags() end,
  },
  prompts = {
    ask_append = { prompt = "", ask = true },
    ask_this = { prompt = "@this: ", ask = true, submit = true },
    diagnostics = { prompt = "Explain @diagnostics", submit = true },
    diff = { prompt = "Review the following git diff for correctness and readability: @diff", submit = true },
    document = { prompt = "Add comments documenting @this", submit = true },
    explain = { prompt = "Explain @this and its context", submit = true },
    fix = { prompt = "Fix @diagnostics", submit = true },
    implement = { prompt = "Implement @this", submit = true },
    optimize = { prompt = "Optimize @this for performance and readability", submit = true },
    review = { prompt = "Review @this for correctness and readability", submit = true },
    test = { prompt = "Add tests for @this", submit = true },
  },
  ask = {
    prompt = "Ask codex: ",
    blink_cmp_sources = { "codex", "buffer" },
    snacks = {
      icon = "󰚩 ",
      win = {
        title_pos = "left",
        relative = "cursor",
        row = -3,
        col = 0,
      },
    },
  },
  select = {
    prompt = "codex: ",
    sections = {
      prompts = true,
      commands = {
        ["turn.interrupt"] = "Interrupt the current turn",
        ["thread.new"] = "Start a new thread",
        ["thread.id"] = "Show the current thread id",
      },
    },
    snacks = {
      preview = "preview",
      layout = {
        preset = "vscode",
        hidden = {},
      },
    },
  },
  output = {
    auto_open = true,
    width = math.floor(vim.o.columns * 0.35),
    show_details = false,
    append_history = true,
  },
}

---@type codex.Opts
M.opts = vim.tbl_deep_extend("force", vim.deepcopy(defaults), vim.g.codex_opts or {})

local user_opts = vim.g.codex_opts or {}
for _, field in ipairs({ "contexts", "prompts" }) do
  if user_opts[field] and M.opts[field] then
    for k, v in pairs(user_opts[field]) do
      if not v then
        M.opts[field][k] = nil
      end
    end
  end
end

return M
