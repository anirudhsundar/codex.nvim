local Promise = require("codex.promise")

local M = {}

---@class codex.connection.Pending
---@field resolve fun(result: any)
---@field reject fun(err: any)

local state = {
  job_id = nil,
  next_id = 1,
  pending = {},
  start_promise = nil,
  ready = false,
  request_handlers = {},
  listeners = {},
}

local function reset()
  state.job_id = nil
  state.ready = false
  state.start_promise = nil
  state.pending = {}
end

local function emit(event, payload)
  for _, cb in ipairs(state.listeners[event] or {}) do
    local ok, err = pcall(cb, payload)
    if not ok then
      vim.schedule(function()
        vim.notify("codex.nvim listener error: " .. err, vim.log.levels.ERROR, { title = "codex" })
      end)
    end
  end
end

---@param event string
---@param cb fun(payload: any)
function M.on(event, cb)
  state.listeners[event] = state.listeners[event] or {}
  table.insert(state.listeners[event], cb)
end

---@param method string
---@param handler fun(params: table, raw: table): any|codex.promise
function M.register_request_handler(method, handler)
  state.request_handlers[method] = handler
end

local function send_payload(payload)
  if not state.job_id then
    return false, "codex app-server not running"
  end
  local ok, encoded = pcall(vim.fn.json_encode, payload)
  if not ok then
    return false, "Failed to encode payload: " .. tostring(encoded)
  end
  local sent = vim.fn.chansend(state.job_id, encoded .. "\n")
  if sent == 0 then
    return false, "Failed to send payload to codex"
  end
  return true
end

local function send_response(id, result)
  return send_payload({ id = id, result = result or vim.NIL })
end

local function send_error(id, message)
  send_payload({
    id = id,
    error = {
      code = -32000,
      message = message,
      data = nil,
    },
  })
end

local function handle_response(msg)
  local pending = state.pending[msg.id]
  if not pending then
    return
  end
  state.pending[msg.id] = nil

  if msg.error then
    pending.reject(msg.error)
  else
    pending.resolve(msg.result)
  end
end

local function handle_request(msg)
  local handler = state.request_handlers[msg.method]
  if not handler then
    send_error(msg.id, "Unhandled request: " .. msg.method)
    return
  end

  local ok, result = pcall(handler, msg.params or {}, msg)
  if not ok then
    send_error(msg.id, result)
    return
  end

  if type(result) == "table" and result.is_promise then
    ---@cast result codex.promise
    result
      :next(function(res)
        send_response(msg.id, res)
      end)
      :catch(function(err)
        send_error(msg.id, tostring(err))
      end)
  else
    send_response(msg.id, result)
  end
end

local function trigger_autocmd(notification)
  vim.schedule(function()
    vim.api.nvim_exec_autocmds("User", {
      pattern = "CodexEvent:" .. notification.method,
      data = notification,
    })
  end)
end

local function handle_notification(msg)
  emit("notification", msg)
  emit(msg.method, msg.params)
  trigger_autocmd(msg)
end

local function handle_lines(data)
  for _, line in ipairs(data) do
    if line ~= nil and line ~= "" then
      local ok, msg = pcall(vim.fn.json_decode, line)
      if not ok then
        vim.schedule(function()
          vim.notify("codex.nvim failed to parse message: " .. tostring(line), vim.log.levels.WARN, { title = "codex" })
        end)
      elseif msg.result or msg.error then
        handle_response(msg)
      elseif msg.method and msg.id ~= nil then
        handle_request(msg)
      elseif msg.method then
        handle_notification(msg)
      end
    end
  end
end

local function send_initialize(resolve, reject)
  local id = state.next_id
  state.next_id = state.next_id + 1
  local ok = send_payload({
    id = id,
    method = "initialize",
    params = {
      clientInfo = {
        name = "codex.nvim",
        title = "Codex Neovim Plugin",
        version = "0.1.0",
      },
    },
  })
  if not ok then
    reject("Failed to send initialize request to codex")
    return
  end

  state.pending[id] = {
    resolve = function(_)
      send_payload({ method = "initialized" })
      state.ready = true
      emit("ready", true)
      resolve(true)
    end,
    reject = reject,
  }
end

---Start (or reuse) the codex app-server process.
---@return codex.promise
function M.start()
  if state.ready and state.job_id then
    return Promise.new(function(resolve)
      resolve(true)
    end)
  end
  if state.start_promise then
    return state.start_promise
  end

  state.start_promise = Promise.new(function(resolve, reject)
    local cmd = require("codex.config").opts.cmd or "codex app-server"
    local job_id = vim.fn.jobstart(cmd, {
      stdout_buffered = false,
      on_stdout = function(_, data)
        handle_lines(data)
      end,
      on_stderr = function(_, data)
        for _, line in ipairs(data or {}) do
          if line and line ~= "" then
            vim.schedule(function()
              vim.notify(line, vim.log.levels.WARN, { title = "codex" })
            end)
          end
        end
      end,
      on_exit = function(_, code)
        reset()
        emit("exit", code)
      end,
    })

    if job_id <= 0 then
      state.start_promise = nil
      reject("Failed to start codex app-server")
      return
    end

    state.job_id = job_id
    send_initialize(resolve, function(err)
      state.start_promise = nil
      reject(err)
    end)
  end)

  return state.start_promise
end

function M.stop()
  if state.job_id then
    pcall(vim.fn.jobstop, state.job_id)
  end
  reset()
end

function M.toggle()
  if state.job_id then
    M.stop()
  else
    M.start()
  end
end

---@return boolean
function M.is_ready()
  return state.ready
end

---Send a request to the app-server.
---@param method string
---@param params table|nil
---@return codex.promise
function M.request(method, params)
  return M.start():next(function()
    return Promise.new(function(resolve, reject)
      local id = state.next_id
      state.next_id = state.next_id + 1

      local ok, err = send_payload({
        id = id,
        method = method,
        params = params,
      })
      if not ok then
        reject(err)
        return
      end

      state.pending[id] = { resolve = resolve, reject = reject }
    end)
  end)
end

---Send a notification (fire and forget).
---@param method string
---@param params table|nil
function M.notify(method, params)
  M.start():next(function()
    send_payload({
      method = method,
      params = params,
    })
  end)
end

return M
