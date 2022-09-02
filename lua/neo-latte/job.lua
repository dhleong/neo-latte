local ui = require'neo-latte.ui'

local default_slow_job_timeout_ms = 3000

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

-- If slow_job_timeout is not `0`, it is a duration in ms (defualting to
-- default_slow_job_timeout_ms) after which a still-running job is shown
---@param type TestType
---@param position Position
---@param command string[]
---@params args { on_exit: fun(exit_code: number), slow_job_timeout: number|nil, win_id: number|nil }
function Job:start(type, position, command, args)
  if args.win_id then
    vim.api.nvim_set_current_win(args.win_id)
    vim.cmd([[enew]])
  else
    vim.cmd([[-tabnew]])
  end

  local job = Job:new{
    buf_id = vim.fn.bufnr('%'),
    command = command,
    position = position,
    type = type,
  }

  local slow_job = {}

  job.job_id = vim.fn.termopen(table.concat(command, ' '), {
    cwd = args.cwd,
    on_exit = function (_, exit_code)
      if args.on_exit then
        args.on_exit(exit_code)
      end

      if slow_job.show_timer then
        slow_job.show_timer:close()
      end

      if exit_code == 0 then
        ui.success('Test success!')
      elseif exit_code < 128 then
        -- NOTE: exit_code of >= 128 means it was killed by signal
        job:show()
      end

      -- Clear "modified" flag after a delay so we can close the terminal
      -- window without nvim whining. For some reason we can't just set this
      -- here; I think neovim writes something to the buffer after calling
      -- our on_exit callback...
      vim.defer_fn(function ()
        if job:find_win_id() then
          vim.api.nvim_buf_set_option(job.buf_id, 'modified', false)
        end
      end, 50)
    end
  })

  vim.bo.bufhidden = 'hide'
  vim.cmd([[normal G]])
  if args.win_id then
    vim.cmd([[wincmd p]])
  else
    vim.cmd('hide')
  end

  if args.slow_job_timeout ~= 0 then
    slow_job.show_timer = vim.defer_fn(function()
      slow_job.show_timer = nil
      job:show()
    end, args.slow_job_timeout or default_slow_job_timeout_ms)
  end

  return job
end

function Job:find_win_id()
  local win_id = vim.fn.bufwinid(self.buf_id)
  if win_id ~= -1 then
    return win_id
  end
end

function Job:kill()
  vim.fn.jobstop(self.job_id)
end

function Job:hide()
  local win_id = self:find_win_id()
  if not win_id then
    -- No window or buffer gone; nop
    return
  end

  vim.api.nvim_win_close(win_id, true)
end

function Job:show()
  local current_win = self:find_win_id()
  if current_win then
    -- Already shown; quickly select the window so we can scroll
    vim.api.nvim_set_current_win(current_win)
  else
    vim.cmd([[aboveleft 10split | e #]] .. self.buf_id)
  end

  vim.bo.bufhidden = 'wipe'
  vim.cmd([[normal G]])
  vim.cmd([[wincmd p]])
end

return Job
