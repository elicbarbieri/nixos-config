{ ... }: {
  extraFiles."lua/hypr.lua".text = ''
    local M = {}

    local function dispatch(lua_expr)
      local res = vim.system({ "hyprctl", "dispatch", lua_expr }):wait()
      if res.code ~= 0 then
        vim.notify("hyprctl dispatch failed: " .. (res.stdout or "") .. (res.stderr or ""), vim.log.levels.ERROR)
      end
    end

    local function sh_join(argv)
      return table.concat(vim.tbl_map(function(a) return "'" .. (a:gsub("'", [['"'"']])) .. "'" end, argv), " ")
    end

    -- dwindle preselect = one-shot, consumed by next window opened on workspace
    function M.preselect_right()
      dispatch('hl.dsp.layout("preselect r")')
    end

    function M.spawn_right(argv)
      M.preselect_right()
      vim.system(argv, { detach = true })
    end

    -- exec rules = window rules scoped to spawned pid (size takes expressions, not "80%")
    function M.spawn_float(argv)
      dispatch(string.format(
        'hl.dsp.exec_cmd(%q, { float = true, center = true, size = "monitor_w*0.8 monitor_h*0.8" })',
        sh_join(argv)
      ))
    end

    return M
  '';
}
