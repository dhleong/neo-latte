---@class Job
---@field buf_id number
---@field command string[]
---@field job_id number
local Job = {}

---@param args { buf_id: number, command: string[], job_id: number }
---@return Job
function Job:new(args)
  local o = vim.tbl_deep_extend('force', {}, args)

  setmetatable(o, self)
  self.__index = self

  return o
end

function Job:kill()
  vim.fn.jobstop(self.job_id)
end

function Job:show()
  vim.cmd([[aboveleft 10split | e #]] .. self.buf_id)
  vim.cmd([[normal G]])
  vim.cmd([[wincmd p]])
end

return Job
