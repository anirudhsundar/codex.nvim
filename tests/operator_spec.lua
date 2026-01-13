local h = require("codex_test_helpers")

describe("codex.api.operator", function()
  before_each(function()
    h.reset_modules()
  end)

  it("sets operatorfunc and returns g@", function()
    local op = require("codex.api.operator")
    local res = op.operator("Explain @this")
    assert.equals("g@", res)
    assert.equals("v:lua.codex_prompt_operator", vim.o.operatorfunc)
  end)
end)
