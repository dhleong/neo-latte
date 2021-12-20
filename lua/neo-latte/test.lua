local Job = require'neo-latte.job'
local ui = require'neo-latte.ui'

local M = {}

---@param type string "'file', 'nearest', or 'suite'
---@param arguments table
---@return Job | nil
function M.run(type, position, arguments)
  local command = M.get_command(type, position or M.create_position(), arguments)
  if not command then
    return
  end

  -- FIXME: Find existing window

  vim.cmd([[-tabnew]])
  local job = Job:new{
    buf_id = vim.fn.bufnr('%'),
    command = command,
  }

  job.job_id = vim.fn.termopen(table.concat(command, ' '), {
    on_exit = function (_, exit_code)
      if exit_code == 0 then
        ui.success('Test success!')
      elseif exit_code < 128 then
        -- NOTE: exit_code of >= 128 means it was killed by signal
        print(vim.inspect(job))
        job:show()
      end
    end
  })
  vim.bo.bufhidden = 'hide'
  vim.cmd('hide')

  return job
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
