local h = require("codex_test_helpers")

describe("codex.config", function()
  before_each(function()
    h.reset_modules()
  end)

  it("merges user opts and removes disabled entries", function()
    vim.g.codex_opts = {
      contexts = {
        ["@this"] = false,
        ["@custom"] = function()
          return "custom"
        end,
      },
      prompts = {
        diff = false,
        custom = { prompt = "Hi", submit = true },
      },
    }
    local config = require("codex.config")
    assert.is_nil(config.opts.contexts["@this"])
    assert.is_function(config.opts.contexts["@custom"])
    assert.is_nil(config.opts.prompts.diff)
    assert.is_truthy(config.opts.prompts.custom)
  end)
end)
