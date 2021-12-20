local defaults = {
  ---@type TestType
  default_type = 'file',
}

return function(name)
  local full_name = 'neolatte_' .. name
  return vim.b[full_name] or vim.g[full_name] or defaults[name]
end
