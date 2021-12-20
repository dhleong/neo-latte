local M = {}

function M.run(type, position, arguments)
  local command = M.get_command(type, position or M.create_position(), arguments)
  if not command then
    print('No test/runner available.')
  end

  vim.cmd([[topleft 10split | term ]] .. table.concat(command, ' '))
  vim.cmd([[wincmd p]])
end

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
  local strategy = 'neovim' -- TODO: strategy

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
