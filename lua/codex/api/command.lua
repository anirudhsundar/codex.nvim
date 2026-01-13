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
  ["model.set"] = function()
    local opts = require("codex.config").opts
    local session = require("codex.session")
    local function set_reasoning(model_item)
      if not model_item or not model_item.efforts or #model_item.efforts == 0 then
        session.set_reasoning_effort(nil)
        return
      end
      vim.ui.select(model_item.efforts, {
        prompt = string.format("Reasoning effort for %s", model_item.id),
        format_item = function(e)
          return e.label or e.id or e
        end,
      }, function(choice)
        if choice then
          session.set_reasoning_effort(choice.id or choice.effort or choice.reasoning_effort or choice)
          vim.notify(
            "Codex model set to: "
              .. model_item.id
              .. " (effort: "
              .. (choice.id or choice.effort or choice.reasoning_effort or choice)
              .. ")",
            vim.log.levels.INFO,
            { title = "codex" }
          )
        else
          vim.notify("Codex model set to: " .. model_item.id, vim.log.levels.INFO, { title = "codex" })
        end
      end)
    end

    local function set_model(item)
      if item and item.id then
        session.set_model(item.id)
        set_reasoning(item)
      elseif item and item ~= "" then
        session.set_model(item)
        session.set_reasoning_effort(nil)
        vim.notify("Codex model set to: " .. item, vim.log.levels.INFO, { title = "codex" })
      end
    end

    local function to_model_list(result)
      if not result then
        return nil
      end
      local raw = result.data or result.models or result
      if raw and raw.data then
        raw = raw.data
      end
      if vim.tbl_islist(raw) then
        return raw
      elseif type(raw) == "table" then
        local list = {}
        for _, v in pairs(raw) do
          table.insert(list, v)
        end
        return list
      end
      return nil
    end

    local function to_items(models)
      local items = {}
      for _, m in ipairs(models or {}) do
        local id = m.id or m.model or m.name or m
        local label = id
        if m.display_name and m.display_name ~= "" then
          label = string.format("%s (%s)", m.display_name, id)
        elseif m.description and m.description ~= "" then
          label = string.format("%s (%s)", id, m.description)
        end
        local efforts = {}
        local effort_list = m.supported_reasoning_efforts or m.supportedReasoningEfforts
        if effort_list then
          for _, e in ipairs(effort_list) do
            local eid = e.reasoning_effort or e.reasoningEffort or e.id or e
            local elabel = e.description or e.reasoning_effort or e.reasoningEffort or eid
            table.insert(efforts, { id = eid, label = elabel })
          end
        end
        table.insert(items, { id = id, label = label, efforts = efforts })
      end
      return items
    end

    local function to_items_from_strings(list)
      local items = {}
      for _, m in ipairs(list or {}) do
        table.insert(items, { id = m, label = m })
      end
      return items
    end

    local function choose(items)
      items = items or {}
      if #items == 0 then
        vim.ui.input({ prompt = "Codex model: " }, set_model)
        return
      end
      table.insert(items, { manual = true, label = "Enter model manually…" })
      vim.ui.select(items, {
        prompt = "Choose Codex model",
        format_item = function(item)
          return item.label
        end,
      }, function(choice)
        if not choice then
          return
        end
        if choice.manual then
          vim.ui.input({ prompt = "Codex model: " }, set_model)
        else
          set_model(choice)
        end
      end)
    end

    -- Try to fetch from Codex first
    require("codex.connection")
      .start()
      :next(function()
        return require("codex.connection").request("model/list", { cursor = vim.NIL, limit = vim.NIL })
      end)
      :next(function(result)
        local models = to_model_list(result)
        local items = models and to_items(models) or {}
        if (#items == 0) and opts.models and #opts.models > 0 then
          items = to_items_from_strings(opts.models)
        end
        choose(items)
      end)
      :catch(function(err)
        vim.notify("Failed to fetch models from Codex: " .. tostring(err), vim.log.levels.WARN, { title = "codex" })
        local items = opts.models and to_items_from_strings(opts.models) or {}
        choose(items)
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
