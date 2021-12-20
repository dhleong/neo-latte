local Job = require'neo-latte.job'

local M = {}

---@alias TestType "'file'" | "'nearest'" | "'suite'"
---@alias Position { file: string, line: number, col: number }

---@param type TestType
---@param args { command: string[]|nil, position: Position|nil, arguments: string[], on_exit: fun(exit_code: number) }
---@return Job | nil
function M.run(type, args)
  local position = args.position or M.create_position()
  local command = args.command or M.get_command(type, position, args.arguments)
  if not command then
    return
  end

  -- FIXME: Find existing window

  local job = Job:start(type, position, command, {
    on_exit = function (exit_code)
      if args.on_exit then
        args.on_exit(exit_code)
      end
    end
  })
  return job
end

---@return Position
function M.create_position(path)
  local filename_modifier = vim.g['test#filename_modifier'] or ':.'
  local full_path = path or vim.fn.expand('%:p')

  return {
    path = full_path,
    file = vim.fn.fnamemodify(full_path, filename_modifier),
    line = path and 1 or vim.fn.line('.'),
    col = path and 1 or vim.fn.col('.'),
  }
end

function M.get_command(type, position, arguments)
  if not vim.fn['test#test_file'](position.file) then
    return
  end

  local runner = vim.fn['test#determine_runner'](position.file)
  local strategy = 'neovim' -- NOTE: We don't actually use this

  local args = vim.fn['test#base#build_position'](runner, type, position)
  vim.list_extend(args, arguments or {})
  args = vim.fn['test#base#options'](runner, args, type)
  args = vim.fn['test#base#build_args'](runner, args, strategy)

  local executable = vim.fn['test#base#executable'](runner)
  local cmd = vim.list_slice(args)
  table.insert(cmd, 1, executable)

  return cmd
end

return M
