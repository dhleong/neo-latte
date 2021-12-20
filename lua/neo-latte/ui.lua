vim.cmd([[
  hi PassBar term=reverse ctermfg=white ctermbg=green guifg=#f0f0f0 guibg=#00bb00
]])

local M = {}

---@param message string
function M.success(message)
  if message:len() >= vim.o.columns - 1 then
    -- take the *last* text since that seems to be the most likely place
    -- for relevant messages (maybe not always though...?)
    local start = message:len() - vim.o.columns - 2
    message = message:sub(start)
  else
    message = message .. string.rep(' ', vim.o.columns - message:len() - 1)
  end

  local oldshowcmd = vim.o.showcmd
  vim.o.showcmd = false

  vim.cmd([[echohl PassBar]])

  -- Clear out anything old
  vim.cmd([[echo '']])
  vim.cmd([[redraw!]])

  vim.cmd([[echom ']] .. vim.fn.escape(message, "'") .. "'")

  vim.cmd([[echohl None]])
  vim.o.showcmd = oldshowcmd
end

return M
