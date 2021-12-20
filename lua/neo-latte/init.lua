local prefs = require'neo-latte.prefs'
local test = require'neo-latte.test'

local state = {}

local M = {}

---@param type TestType
function M.toggle_auto_test(type)
  local was_enabled = vim.b.neo_latte_autorun
  vim.b.neo_latte_autorun = not was_enabled

  local last_job = state.last_job
  if last_job then
    last_job:kill()
  end

  state.last_job = test.run(type or prefs'default_type', {
    on_exit = function (exit_code)
      if last_job and exit_code == 0 then
        last_job:hide()
      end
    end
  })
  if not state.last_job then
    print('No test/runner available')
  end

  if not was_enabled then
    print('Enabled neo-latte auto test')
  else
    print('Disabled neo-latte auto test')
  end
end

return M
