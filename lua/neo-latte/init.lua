local prefs = require'neo-latte.prefs'
local test = require'neo-latte.test'

local state = {}

local M = {}

---@param type TestType
function M.toggle_auto_test(type)
  local was_enabled = vim.b.neo_latte_autorun
  vim.b.neo_latte_autorun = not was_enabled

  if not was_enabled then
    M.enable_auto_test(type)
    print('Enabled neo-latte auto test; running now...')
  else
    M.disable_auto_test()
    print('Disabled neo-latte auto test')
  end
end

function M.enable_auto_test(type)
  M.run(type, { silent = true })
  vim.cmd([[
    augroup NeoLatteAutoRun
      autocmd!
      autocmd BufWritePost * lua require'neo-latte'.retry()
    augroup END
  ]])
end

function M.disable_auto_test()
  vim.cmd([[
    augroup NeoLatteAutoRun
      autocmd!
    augroup END
  ]])
  vim.cmd([[augroup! NeoLatteAutoRun]])
end

function M.retry()
  local last_job = state.last_job
  if not last_job then
    return
  end

  last_job:kill()

  M.run(last_job.type, {
    command = last_job.command,
  })
end

-- Begin running the requested test type
---@param type TestType
---@param opts { command: string[], silent: boolean }
function M.run(type, opts)
  local options = opts or {}
  local last_job = state.last_job
  if last_job then
    last_job:kill()
  end

  state.last_job = test.run(type or prefs'default_type', {
    command = opts.command,
    on_exit = function (exit_code)
      if last_job and exit_code == 0 then
        last_job:hide()
      end
    end
  })

  if not state.last_job then
    print('No test/runner available')
  elseif not options.silent then
    print('Running test...')
  end
end

-- Stop the most-recent test job, if it's still running
function M.stop()
  local job = state.last_job
  if job then
    job:kill()
  end
end

return M
