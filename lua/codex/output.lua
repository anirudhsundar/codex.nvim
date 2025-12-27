local M = {
  buf = nil,
  win = nil,
  show_details = nil,
  current_section = {
    id = nil,
    start = 0,
    len = 0,
  },
}

local function ensure_buf()
  if M.buf and vim.api.nvim_buf_is_valid(M.buf) then
    return
  end

  M.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = M.buf })
  vim.api.nvim_set_option_value("bufhidden", "hide", { buf = M.buf })
  vim.api.nvim_set_option_value("swapfile", false, { buf = M.buf })
  vim.api.nvim_set_option_value("filetype", "codex", { buf = M.buf })
end

local function ensure_win()
  ensure_buf()
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    return
  end

  local opts = require("codex.config").opts.output or {}
  local width = opts.width or math.floor(vim.o.columns * 0.35)

  M.win = vim.api.nvim_open_win(M.buf, false, {
    split = "right",
    width = width,
  })
  vim.api.nvim_set_option_value("winbar", "codex", { win = M.win })
end

local function apply_filetype(ft)
  pcall(vim.api.nvim_set_option_value, "filetype", ft, { buf = M.buf })
end

---Render lines for a turn section.
---@param lines string[]
---@param as_markdown boolean
---@param section_id string|nil
function M.render(lines, as_markdown, section_id)
  ensure_buf()
  local opts = require("codex.config").opts.output or {}
  if opts.auto_open ~= false then
    ensure_win()
  end

  local append_mode = opts.append_history ~= false
  vim.api.nvim_set_option_value("modifiable", true, { buf = M.buf })

  local content = lines
  if as_markdown then
    content = vim.lsp.util.convert_input_to_markdown_lines(lines)
  end

  if not append_mode then
    vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, content)
    apply_filetype(as_markdown and "markdown" or "codex")
    M.current_section = { id = section_id, start = 0, len = #content }
  else
    if M.current_section.id ~= section_id then
      -- Append new section
      local line_count = vim.api.nvim_buf_line_count(M.buf)
      local start = line_count
      -- Trim trailing empty single line (fresh buffer)
      if line_count == 1 then
        local existing = vim.api.nvim_buf_get_lines(M.buf, 0, -1, false)
        if existing[1] == "" then
          start = 0
        end
      end
      if start > 0 then
        vim.api.nvim_buf_set_lines(M.buf, start, start, false, { "" })
        start = start + 1
      end
      vim.api.nvim_buf_set_lines(M.buf, start, start, false, content)
      M.current_section = { id = section_id, start = start, len = #content }
    else
      -- Replace current section
      local s = M.current_section.start
      vim.api.nvim_buf_set_lines(M.buf, s, s + M.current_section.len, false, content)
      M.current_section.len = #content
    end
    apply_filetype("codex")
  end
  vim.api.nvim_set_option_value("modifiable", false, { buf = M.buf })
end

function M.close()
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    vim.api.nvim_win_close(M.win, true)
  end
  M.win = nil
  M.current_section = { id = nil, start = 0, len = 0 }
end

function M.details_enabled()
  if M.show_details == nil then
    M.show_details = require("codex.config").opts.output.show_details or false
  end
  return M.show_details
end

function M.toggle_details()
  M.show_details = not M.details_enabled()
  vim.notify("codex output details: " .. (M.show_details and "shown" or "hidden"), vim.log.levels.INFO, { title = "codex" })
end

return M
