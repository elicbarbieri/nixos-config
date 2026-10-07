{ ... }: {
  extraFiles."lua/hypr.lua".text = ''
    local M = {}

    local function dispatch(lua_expr)
      local res = vim.system({ "hyprctl", "dispatch", lua_expr }):wait()
      if res.code ~= 0 then
        vim.notify("hyprctl dispatch failed: " .. (res.stdout or "") .. (res.stderr or ""), vim.log.levels.ERROR)
      end
    end

    -- dwindle preselect = one-shot, consumed by next window opened on workspace
    function M.preselect_right()
      dispatch('hl.dsp.layout("preselect r")')
    end

    return M
  '';
}
