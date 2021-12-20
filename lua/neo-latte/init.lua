local test = require'neo-latte.test'

local M = {}

function M.toggle_auto_test()
  local was_enabled = vim.b.neo_latte_autorun
  vim.b.neo_latte_autorun = not was_enabled

  -- TODO
  local job = test.run('file')
  if not job then
    print('No test/runner available')
  end

  if not was_enabled then
    print('Enabled neo-latte auto test')
  else
    print('Disabled neo-latte auto test')
  end
end

return M
