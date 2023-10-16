local defaults = {
  ---@type TestType
  default_type = 'file',

  ---If true (default), the output window (if any has been shown) will be
  ---hidden if the test run passes.
  hide_output_on_success = true,

  ---Duration in ms, after which a still-running job will be shown. Can
  ---be overridden at the Job level with the `slow_job_timeout` param.
  show_jobs_after_ms = 2000,
}

return function(name)
  local full_name = 'neolatte_' .. name
  return vim.b[full_name] or vim.g[full_name] or defaults[name]
end
