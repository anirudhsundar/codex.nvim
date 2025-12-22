local M = {
  buf = nil,
  win = nil,
  show_details = nil,
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

function M.render(lines, as_markdown)
  ensure_buf()
  local opts = require("codex.config").opts.output or {}
  if opts.auto_open ~= false then
    ensure_win()
  end

  vim.api.nvim_set_option_value("modifiable", true, { buf = M.buf })
  if as_markdown then
    local md = vim.lsp.util.convert_input_to_markdown_lines(lines)
    md = vim.lsp.util.stylize_markdown(M.buf, md, { max_width = 80 })
    vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, md)
    apply_filetype("markdown")
  else
    vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, lines)
    apply_filetype("codex")
  end
  vim.api.nvim_set_option_value("modifiable", false, { buf = M.buf })
end

function M.close()
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    vim.api.nvim_win_close(M.win, true)
  end
  M.win = nil
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
