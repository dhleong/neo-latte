local Job = require 'neo-latte.job'

local function activate_project_root()
  if vim.g['test#project_root'] == nil then
    return function()
      -- nop
    end
  end

  local cmd = 'cd ' .. vim.g['test#project_root']
  vim.fn.execute(cmd)

  return function()
    vim.fn.execute('cd -')
  end
end

local M = {}

---@alias TestType "'file'" | "'nearest'" | "'suite'"
---@alias Position { file: string, line: number, col: number }

---@alias TestCommandArgs { command: string[]|nil, position: Position|nil, arguments: string[], remove_arguments: string[], on_exit: fun(job: Job, exit_code: number), win_id: number|nil, origin_win_id: number|nil }

---@param type TestType
---@param args TestCommandArgs
---@return Job | nil
function M.run(type, args)
  local leave_project_root = activate_project_root()

  local position = args.position or M.create_position()
  local command = args.command or M.get_command(type, position, args.arguments)

  leave_project_root()

  if not command then
    return
  end

  if args.remove_arguments then
    command = vim.tbl_filter(function(arg)
      return not vim.tbl_contains(args.remove_arguments, arg)
    end, command)
  end

  local job = Job:start(type, position, command, {
    cwd = vim.g['test#project_root'],
    win_id = args and args.win_id,
    origin_win_id = (args and args.origin_win_id) or vim.fn.win_getid(),
    on_exit = function(job, exit_code)
      if args.on_exit then
        args.on_exit(job, exit_code)
      end
    end
  })
  return job
end

---@return Position
function M.create_position()
  local filename_modifier = vim.g['test#filename_modifier'] or ':.'
  local full_path = vim.fn.expand('%:p')

  return {
    path = full_path,
    file = vim.fn.fnamemodify(full_path, filename_modifier),
    line = vim.fn.line('.'),
    col = vim.fn.col('.'),
  }
end

---@return string[]|nil
function M.get_command(type, position, arguments)
  if not vim.fn['test#test_file'](position.file) then
    return
  end

  local strategy = 'neovim' -- NOTE: We don't actually use this
  local runner = vim.fn['test#determine_runner'](position.file)
  if not runner then
    print('No runner available')
    return
  end

  if runner == 0 then
    return
  end

  local args = vim.fn['test#base#build_position'](runner, type, position)
  vim.list_extend(args, arguments or {})
  args = vim.fn['test#base#options'](runner, args, type)
  args = vim.fn['test#base#build_args'](runner, args, strategy)

  local executable = vim.fn['test#base#executable'](runner)

  local cmd = vim.list_slice(args)

  if vim.g['test#project_root'] and string.find(executable, '[/\\]') and executable:sub(0, 1) ~= '/' then
    executable = vim.g['test#project_root'] .. '/' .. executable
  end

  table.insert(cmd, 1, executable)

  return cmd
end

return M
