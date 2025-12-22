local Promise = require("codex.promise")
local connection = require("codex.connection")
local output = require("codex.output")

local M = {}

local state = {
  thread_id = nil,
  turn_id = nil,
  turn_status = "idle",
  user_input = nil,
  items = {},
  order = {},
  diff = nil,
}

local function reset_turn()
  state.turn_id = nil
  state.turn_status = "idle"
  state.user_input = nil
  state.items = {}
  state.order = {}
  state.diff = nil
end

local function append_lines(lines, text, prefix)
  prefix = prefix or ""
  for _, line in ipairs(vim.split(text, "\n", { plain = true })) do
    table.insert(lines, prefix .. line)
  end
end

local function render()
  local show_details = output.details_enabled()
  local lines = {}

  if not show_details then
    local final_text = ""
    for i = #state.order, 1, -1 do
      local item = state.items[state.order[i]]
      if item and item.type == "agentMessage" and item.text and item.text ~= "" then
        final_text = item.text
        break
      end
    end
    if final_text == "" then
      final_text = ("Status: %s"):format(state.turn_status)
    end
    output.render({ final_text }, true)
    return
  end

  table.insert(lines, ("Thread: %s"):format(state.thread_id or "<starting>"))
  table.insert(lines, ("Turn: %s"):format(state.turn_id or "<pending>"))
  table.insert(lines, ("Status: %s"):format(state.turn_status))

  if state.user_input then
    append_lines(lines, state.user_input, "You: ")
  end

  for _, id in ipairs(state.order) do
    local item = state.items[id]
    if item then
      if item.type == "agentMessage" then
        append_lines(lines, item.text or "", "Codex: ")
      elseif item.type == "commandExecution" then
        table.insert(lines, ("Command: %s"):format(item.command or "<unknown>"))
        if item.cwd then
          table.insert(lines, "  cwd: " .. item.cwd)
        end
        if item.status then
          table.insert(lines, "  status: " .. item.status)
        end
        if item.output and item.output ~= "" then
          append_lines(lines, item.output, "  ")
        end
      elseif item.type == "fileChange" then
        table.insert(lines, "File changes:")
        if item.changes then
          for _, change in ipairs(item.changes) do
            table.insert(lines, ("  %s (%s)"):format(change.path or "<file>", change.kind or ""))
          end
        end
        if item.output then
          append_lines(lines, item.output, "  ")
        end
      elseif item.type == "reasoning" then
        if item.summary and #item.summary > 0 then
          append_lines(lines, table.concat(item.summary, "\n"), "Reasoning: ")
        end
        if item.content and #item.content > 0 then
          append_lines(lines, table.concat(item.content, "\n"), "Details: ")
        end
      end
    end
  end

  if state.diff and state.diff ~= "" then
    table.insert(lines, "")
    table.insert(lines, "Diff:")
    append_lines(lines, state.diff, "  ")
  end

  output.render(lines, false)
end

local function upsert_item(new_item)
  local id = new_item.id
  if not state.items[id] then
    state.items[id] = { type = new_item.type, id = id }
    table.insert(state.order, id)
  end
  local item = state.items[id]
  item.type = new_item.type or item.type

  if new_item.type == "agentMessage" then
    item.text = new_item.text or item.text or ""
  elseif new_item.type == "commandExecution" then
    item.command = new_item.command or item.command
    item.cwd = new_item.cwd or item.cwd
    item.status = new_item.status or item.status
    item.output = new_item.output or item.output or ""
    item.command_actions = new_item.command_actions or item.command_actions
  elseif new_item.type == "fileChange" then
    item.changes = new_item.changes or item.changes
    item.status = new_item.status or item.status
  elseif new_item.type == "reasoning" then
    item.summary = new_item.summary or item.summary
    item.content = new_item.content or item.content
  end
end

local function ensure_thread()
  if state.thread_id then
    return Promise.new(function(resolve)
      resolve(state.thread_id)
    end)
  end

  return connection
    .request("thread/start", {
      cwd = vim.fn.getcwd(),
      sandbox = require("codex.config").opts.sandbox,
    })
    :next(function(result)
      if result.thread and result.thread.id then
        state.thread_id = result.thread.id
      end
      render()
      return state.thread_id
    end)
end

function M.send_prompt(prompt_text)
  state.user_input = prompt_text
  state.turn_status = "starting"
  render()

  return ensure_thread()
    :next(function(thread_id)
      return connection.request("turn/start", {
        threadId = thread_id,
        input = {
          {
            type = "text",
            text = prompt_text,
          },
        },
        cwd = vim.fn.getcwd(),
      })
    end)
    :next(function(response)
      if response.turn then
        state.turn_id = response.turn.id
        state.turn_status = response.turn.status or "inProgress"
      end
      render()
      return response
    end)
end

function M.interrupt()
  if not state.thread_id or not state.turn_id then
    vim.notify("No active codex turn to interrupt", vim.log.levels.INFO, { title = "codex" })
    return
  end
  connection.request("turn/interrupt", {
    threadId = state.thread_id,
    turnId = state.turn_id,
  })
end

function M.new_thread()
  reset_turn()
  state.thread_id = nil
  render()
end

local function handle_command_approval(params)
  local item = state.items[params.itemId]
  local description = params.reason or (item and item.command) or "Command"
  local choices = {
    { label = "Accept", decision = "accept" },
    { label = "Accept for session", decision = "acceptForSession" },
    { label = "Decline", decision = "decline" },
  }

  return Promise.new(function(resolve)
    vim.schedule(function()
      vim.ui.select(choices, {
        prompt = "Allow codex to run: " .. description,
        format_item = function(choice)
          return choice.label
        end,
      }, function(choice)
        if choice then
          resolve({ decision = choice.decision })
        else
          resolve({ decision = "cancel" })
        end
      end)
    end)
  end)
end

local function handle_file_change_approval(params)
  local item = state.items[params.itemId]
  local target = "<files>"
  if item and item.changes and item.changes[1] and item.changes[1].path then
    target = item.changes[1].path
  end

  return Promise.new(function(resolve)
    vim.schedule(function()
      vim.ui.select({ "Accept", "Decline" }, {
        prompt = "Allow codex to modify " .. target .. "?",
      }, function(choice)
        if choice == "Accept" then
          resolve({ decision = "accept" })
        elseif choice == "Decline" then
          resolve({ decision = "decline" })
        else
          resolve({ decision = "cancel" })
        end
      end)
    end)
  end)
end

local function register_handlers()
  connection.register_request_handler("item/commandExecution/requestApproval", handle_command_approval)
  connection.register_request_handler("item/fileChange/requestApproval", handle_file_change_approval)

  connection.on("thread/started", function(params)
    local thread = params.thread or params.thread
    if thread and thread.id then
      state.thread_id = thread.id
      render()
    end
  end)

  connection.on("turn/started", function(params)
    reset_turn()
    state.thread_id = params.threadId or state.thread_id
    local turn = params.turn or params.turn
    if turn then
      state.turn_id = turn.id
      state.turn_status = turn.status or "inProgress"
    end
    render()
  end)

  connection.on("turn/completed", function(params)
    local turn = params.turn or params.turn
    state.turn_id = turn and turn.id or state.turn_id
    if turn and turn.status then
      state.turn_status = turn.status
    end
    render()
  end)

  connection.on("item/started", function(params)
    if params.item then
      upsert_item(params.item)
      render()
    end
  end)

  connection.on("item/completed", function(params)
    if params.item then
      upsert_item(params.item)
      render()
    end
  end)

  connection.on("item/agentMessage/delta", function(params)
    local item = state.items[params.itemId]
    if not item then
      item = { id = params.itemId, type = "agentMessage", text = "" }
      state.items[params.itemId] = item
      table.insert(state.order, params.itemId)
    end
    item.type = "agentMessage"
    item.text = (item.text or "") .. (params.delta or "")
    render()
  end)

  connection.on("item/commandExecution/outputDelta", function(params)
    local item = state.items[params.itemId]
    if not item then
      item = { id = params.itemId, type = "commandExecution", output = "" }
      state.items[params.itemId] = item
      table.insert(state.order, params.itemId)
    end
    item.type = "commandExecution"
    item.output = (item.output or "") .. (params.delta or "")
    render()
  end)

  connection.on("item/fileChange/outputDelta", function(params)
    local item = state.items[params.itemId]
    if not item then
      item = { id = params.itemId, type = "fileChange", output = "" }
      state.items[params.itemId] = item
      table.insert(state.order, params.itemId)
    end
    item.output = (item.output or "") .. (params.delta or "")
    render()
  end)

  connection.on("item/reasoning/summaryTextDelta", function(params)
    local item = state.items[params.itemId]
    if not item then
      item = { id = params.itemId, type = "reasoning", summary = {} }
      state.items[params.itemId] = item
      table.insert(state.order, params.itemId)
    end
    item.type = "reasoning"
    item.summary = item.summary or {}
    local idx = (params.summaryIndex or 0) + 1
    item.summary[idx] = (item.summary[idx] or "") .. (params.delta or "")
    render()
  end)

  connection.on("item/reasoning/textDelta", function(params)
    local item = state.items[params.itemId]
    if not item then
      item = { id = params.itemId, type = "reasoning", content = {} }
      state.items[params.itemId] = item
      table.insert(state.order, params.itemId)
    end
    item.type = "reasoning"
    item.content = item.content or {}
    local idx = (params.contentIndex or 0) + 1
    item.content[idx] = (item.content[idx] or "") .. (params.delta or "")
    render()
  end)

  connection.on("turn/diff/updated", function(params)
    state.diff = params.diff
    render()
  end)
end

register_handlers()

function M.status()
  return {
    thread_id = state.thread_id,
    turn_id = state.turn_id,
    turn_status = state.turn_status,
  }
end

return M
