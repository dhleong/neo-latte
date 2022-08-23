local prefs = require 'neo-latte.prefs'
local test = require 'neo-latte.test'
local ui = require 'neo-latte.ui'

---@alias TabPageState { last_job: Job| nil, auto: TestType|nil }

local state = {
  ---@type table<number, TabPageState>
  tabpages = {},
}

local function tabpage()
  local tab_id = vim.api.nvim_get_current_tabpage()
  local existing = state.tabpages[tab_id]
  if existing then
    return existing
  end

  local new_tabpage_state = {}
  state.tabpages[tab_id] = new_tabpage_state
  return new_tabpage_state
end

local M = {}

---@param type TestType
function M.toggle_auto_test(type)
  local tab = tabpage()
  local old_type = tab.auto
  local new_type = type or prefs 'default_type'

  if old_type ~= new_type then
    tab.auto = new_type
  else
    tab.auto = nil
  end

  if tab.auto then
    if M.enable_auto_test(new_type) then
      print('[neo-latte] Enabled "' .. new_type .. '" auto test; running now...')
    else
      tab.auto = nil
    end
  else
    M.disable_auto_test()
    print('[neo-latte] Disabled auto test')
  end
end

function M.enable_auto_test(type)
  if M.run(type, { silent = true }) then
    vim.cmd [[
      augroup NeoLatteAutoRun
        autocmd!
        autocmd BufWritePost * lua require'neo-latte'.retry()
      augroup END
    ]]
    return true
  end
end

function M.disable_auto_test()
  local tab = tabpage()
  local last_job = tab.last_job
  tab.last_job = nil

  if last_job then
    last_job:kill()
    last_job:hide()
  end

  vim.cmd [[
    augroup NeoLatteAutoRun
      autocmd!
    augroup END
    augroup! NeoLatteAutoRun
  ]]
end

function M.retry()
  local tab = tabpage()
  local last_job = tab.last_job
  if not last_job then
    return
  end

  M.run(last_job.type, {
    command = last_job.command,
  })
end

---@alias CommandOpts { command: string[], silent: boolean, add_arguments: string[], remove_arguments: string[] }

-- Begin running the requested test type
---@param test_type TestType|{ type:string }:CommandOpts
---@param opts CommandOpts|nil
function M.run(test_type, opts)
  local options = opts or {}
  local tab = tabpage()
  local last_job = tab.last_job
  if last_job then
    last_job:kill()
  end

  if type(test_type) == 'table' then
    options = test_type
    test_type = test_type.type
  end

  tab.last_job = test.run(test_type or prefs 'default_type', {
    command = options.command,
    arguments = options.add_arguments,
    remove_arguments = options.remove_arguments,
    win_id = last_job and last_job:find_win_id(),
    on_exit = function(exit_code)
      if tab.last_job and exit_code == 0 then
        tab.last_job:hide()
      end
      if exit_code > 0 then
        print('[neo-latte] Test(s) failed')
      end
    end
  })

  ui.clear_echo()
  if not tab.last_job then
    print('[neo-latte] No test/runner available')
    return false
  elseif not options.silent then
    print('[neo-latte] Running test...')
  end

  return true
end

-- Stop the most-recent test job, if it's still running
function M.stop()
  local tab = tabpage()
  local job = tab.last_job
  if job then
    job:kill()
  end
end

return M
