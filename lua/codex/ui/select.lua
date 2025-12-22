---@module 'snacks.picker'

local M = {}

---@class codex.select.Opts : snacks.picker.ui_select.Opts
---@field sections? codex.select.sections.Opts

---@class codex.select.sections.Opts
---@field prompts? boolean
---@field commands? table<string, string>|false

---Select from codex.nvim functionality.
---@param opts? codex.select.Opts
function M.select(opts)
  opts = vim.tbl_deep_extend("force", require("codex.config").opts.select or {}, opts or {})

  local context = require("codex.context").new()
  local prompts = require("codex.config").opts.prompts or {}
  local commands = require("codex.config").opts.select.sections.commands or {}

  ---@type snacks.picker.finder.Item[]
  local items = {}

  if opts.sections.prompts then
    table.insert(items, { __group = true, name = "PROMPT", preview = { text = "" } })
    local prompt_items = {}
    for name, prompt in pairs(prompts) do
      local rendered = context:render(prompt.prompt)
      local item = {
        __type = "prompt",
        name = name,
        text = prompt.prompt .. (prompt.ask and "…" or ""),
        highlights = rendered.input,
        preview = {
          text = context.plaintext(rendered.output),
          extmarks = context.extmarks(rendered.output),
        },
        ask = prompt.ask,
        submit = prompt.submit,
      }
      table.insert(prompt_items, item)
    end
    table.sort(prompt_items, function(a, b)
      return a.name < b.name
    end)
    for _, item in ipairs(prompt_items) do
      table.insert(items, item)
    end
  end

  if type(opts.sections.commands) == "table" then
    table.insert(items, { __group = true, name = "COMMAND", preview = { text = "" } })
    local command_items = {}
    for name, description in pairs(commands) do
      table.insert(command_items, {
        __type = "command",
        name = name,
        text = description,
        highlights = { { description, "Comment" } },
        preview = { text = "" },
      })
    end
    table.sort(command_items, function(a, b)
      return a.name < b.name
    end)
    for _, item in ipairs(command_items) do
      table.insert(items, item)
    end
  end

  for i, item in ipairs(items) do
    item.idx = i
  end

  local select_opts = {
    ---@param item snacks.picker.finder.Item
    ---@param is_snacks boolean
    format_item = function(item, is_snacks)
      if is_snacks then
        if item.__group then
          return { { item.name, "Title" } }
        end
        local formatted = vim.deepcopy(item.highlights)
        if item.ask then
          table.insert(formatted, { "…", "Keyword" })
        end
        table.insert(formatted, 1, { item.name, "Keyword" })
        table.insert(formatted, 2, { string.rep(" ", 18 - #item.name) })
        return formatted
      else
        local indent = #tostring(#items) - #tostring(item.idx)
        if item.__group then
          local divider = string.rep("—", (80 - #item.name) / 2)
          return string.rep(" ", indent) .. divider .. item.name .. divider
        end
        return ("%s[%s]%s%s"):format(string.rep(" ", indent), item.name, string.rep(" ", 18 - #item.name), item.text or "")
      end
    end,
  }
  select_opts = vim.tbl_deep_extend("force", select_opts, opts)

  vim.ui.select(items, select_opts, function(choice)
    context:cleanup()

    if not choice then
      return
    elseif choice.__type == "prompt" then
      local prompt = require("codex.config").opts.prompts[choice.name]
      prompt.context = context
      if prompt.ask then
        require("codex").ask(prompt.prompt, prompt)
      else
        require("codex").prompt(prompt.prompt, prompt)
      end
    elseif choice.__type == "command" then
      require("codex").command(choice.name)
    end
  end)
end

return M
