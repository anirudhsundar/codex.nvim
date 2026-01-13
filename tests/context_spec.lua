local h = require("codex_test_helpers")

describe("codex.context", function()
  local Context

  before_each(function()
    h.reset_modules()
    vim.g.codex_opts = nil
    Context = require("codex.context")
  end)

  it("renders @this with selection", function()
    h.with_tmp_buf({ "hello world" }, function(buf)
      vim.api.nvim_buf_set_name(buf, vim.fn.getcwd() .. "/tmp/file.txt")
      local ctx = Context.new({
        from = { 1, 0 },
        to = { 1, 4 },
        kind = "char",
      })
      local rendered = ctx:render("See @this")
      local plain = Context.plaintext(rendered.output)
      assert.truthy(plain:find("@tmp/file.txt"))
      assert.truthy(plain:find("L1"))
    end)
  end)

  it("renders buffer placeholder", function()
    h.with_tmp_buf({ "hello" }, function(buf)
      vim.api.nvim_buf_set_name(buf, vim.fn.getcwd() .. "/tmp/buf.txt")
      local ctx = Context.new()
      local buf_ref = ctx:buffer()
      assert.is_true(buf_ref:find("@tmp/buf.txt") ~= nil)
    end)
  end)

  it("renders diagnostics placeholder", function()
    h.with_tmp_buf({ "bad line" }, function(buf)
      h.add_diag(buf, "broken")
      local ctx = Context.new()
      local diag = ctx:diagnostics()
      assert.is_true(diag:find("diagnostics") ~= nil)
      assert.is_true(diag:find("broken") ~= nil)
    end)
  end)

  it("renders quickfix placeholder", function()
    h.with_tmp_buf({ "hello" }, function(buf)
      vim.api.nvim_buf_set_name(buf, vim.fn.getcwd() .. "/tmp/qf.txt")
      h.set_qflist({ { bufnr = buf, lnum = 1, col = 1 } })
      local ctx = Context.new()
      local qf = ctx:quickfix()
      assert.truthy(qf:find("@tmp/qf.txt"))
    end)
  end)

  it("renders git diff placeholder", function()
    local orig_popen = io.popen
    io.popen = function()
      return {
        read = function()
          return "diff --git a b"
        end,
        close = function() end,
      }
    end

    h.with_tmp_buf({ "a" }, function(_)
      local ctx = Context.new()
      local diff = ctx:git_diff()
      assert.is_true(diff:find("diff --git") ~= nil)
    end)

    io.popen = orig_popen
  end)
end)
