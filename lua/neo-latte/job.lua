local ui = require 'neo-latte.ui'
local prefs = require 'neo-latte.prefs'

---@class Job
---@field buf_id number
---@field origin_win_id number
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
-- `prefs 'show_jobs_after_ms'`) after which a still-running job is shown
---@param type TestType
---@param position Position
---@param command string[]
---@params args { on_exit: fun(job: Job, exit_code: number), slow_job_timeout: number|nil, win_id: number|nil }
function Job:start(type, position, command, args)
  if args.win_id then
    vim.api.nvim_set_current_win(args.win_id)
    vim.cmd([[enew]])
  else
    vim.cmd([[-tabnew]])
  end

  local job = Job:new {
    buf_id = vim.fn.bufnr('%'),
    command = command,
    position = position,
    type = type,
    origin_win_id = args.origin_win_id,
  }

  local slow_job = {}

  job.job_id = vim.fn.termopen(table.concat(command, ' '), {
    cwd = args.cwd,
    on_exit = function(_, exit_code)
      if args.on_exit then
        args.on_exit(job, exit_code)
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
      vim.defer_fn(function()
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
    end, args.slow_job_timeout or prefs 'show_jobs_after_ms')
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

function Job:has_win()
  return #vim.fn.win_findbuf(self.buf_id) > 0
end

function Job:hide()
  local win_id = self:find_win_id()
  if not win_id then
    -- No window or buffer gone; nop
    return
  end

  vim.api.nvim_win_close(win_id, true)
end

function Job:is_win_focused()
  local my_win = self:find_win_id()
  return vim.api.nvim_get_current_win() == my_win
end

function Job:show()
  if self:is_win_focused() then
    -- Already in the output window; this is a nop, since we don't
    -- want to override the user's preferred location in it
    return
  end

  local focused_window = vim.api.nvim_get_current_win()
  local current_output_win = self:find_win_id()
  if current_output_win then
    -- Already shown; quickly select the window so we can scroll
    vim.api.nvim_set_current_win(current_output_win)
  elseif self:has_win() then
    -- If there's a window *somewhere* then we're probably on a
    -- different tabpage. This should just be a nop
    return
  else
    -- Open a window *only* if there's no window *anywhere*
    if vim.fn.win_id2win(self.origin_win_id) == 0 then
      -- Couldn't find the "origin" window in this tab. We don't
      -- want to show output in the wrong tab, so just no-op for now.
      -- TODO: Can/should we switch back to the origin tab?
      return
    end

    -- First, ensure the "origin" window is focused, so the output shows
    -- up where we expect it to (even if we left the original window)
    vim.api.nvim_set_current_win(self.origin_win_id)
    vim.cmd([[aboveleft 10split | e #]] .. self.buf_id)
  end

  vim.bo.bufhidden = 'wipe'
  vim.cmd([[normal G]])
  vim.cmd([[wincmd p]])

  if focused_window ~= self.origin_win_id then
    -- If we weren't in the origin window, go back to where we were.
    -- Note that the check at the very top of this fn ensures we don't
    -- leave the output window if that's where we started.
    vim.api.nvim_set_current_win(focused_window)
  end
end

return Job
