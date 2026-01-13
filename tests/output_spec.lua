local h = require("codex_test_helpers")

describe("codex.output", function()
  before_each(function()
    h.reset_modules()
    vim.g.codex_opts = { output = { auto_open = false } }
  end)

  it("renders lines into a scratch buffer", function()
    local output = require("codex.output")
    output.render({ "hello", "world" })
    assert.is_truthy(output.buf)
    local lines = vim.api.nvim_buf_get_lines(output.buf, 0, -1, false)
    assert.same({ "hello", "world" }, lines)
  end)
end)
