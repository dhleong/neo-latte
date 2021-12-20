local ui = require'neo-latte.ui'

---@class Job
---@field buf_id number
---@field command string[]
---@field job_id number
---@field position Position
---@field type TestType
local Job = {}

---@return Job
function Job:new(args)
  local o = vim.tbl_deep_extend('force', {}, args)

  setmetatable(o, self)
  self.__index = self

  return o
end

---@param type TestType
---@param position Position
---@param command string[]
---@params args { on_exit: fun(exit_code: number) }
function Job:start(type, position, command, args)
  vim.cmd([[-tabnew]])
  local job = Job:new{
    buf_id = vim.fn.bufnr('%'),
    command = command,
    position = position,
    type = type,
  }

  job.job_id = vim.fn.termopen(table.concat(command, ' '), {
    on_exit = function (_, exit_code)
      if args.on_exit then
        args.on_exit(exit_code)
      end

      if exit_code == 0 then
        ui.success('Test success!')
      elseif exit_code < 128 then
        -- NOTE: exit_code of >= 128 means it was killed by signal
        job:show()
      end
    end
  })
  vim.bo.bufhidden = 'hide'
  vim.cmd('hide')

  return job
end

function Job:kill()
  vim.fn.jobstop(self.job_id)
end

function Job:hide()
  local win_id = vim.fn.bufwinid(self.buf_id)
  if win_id == -1 then
    -- No window or buffer gone; nop
    return
  end

  vim.api.nvim_win_close(win_id, true)
end

function Job:show()
  vim.cmd([[aboveleft 10split | e #]] .. self.buf_id)
  vim.cmd([[normal G]])
  vim.cmd([[wincmd p]])
end

return Job
