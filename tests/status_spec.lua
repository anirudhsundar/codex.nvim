local h = require("codex_test_helpers")

describe("codex.status", function()
  before_each(function()
    h.reset_modules()
  end)

  it("returns disconnected icon when not ready", function()
    package.loaded["codex.connection"] = {
      is_ready = function()
        return false
      end,
    }
    package.loaded["codex.session"] = {
      status = function()
        return { turn_status = "idle" }
      end,
    }
    local status = require("codex.status")
    assert.equals("󱚧", status.statusline())
  end)

  it("returns running icon when turn in progress", function()
    package.loaded["codex.connection"] = {
      is_ready = function()
        return true
      end,
    }
    package.loaded["codex.session"] = {
      status = function()
        return { turn_status = "inProgress" }
      end,
    }
    local status = require("codex.status")
    assert.equals("󱜙", status.statusline())
  end)
end)
