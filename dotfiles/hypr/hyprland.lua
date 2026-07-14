-- =============================================================================
-- Hyprland configuration (Lua)
-- =============================================================================
-- Since Hyprland 0.55 the config format is Lua (hyprlang/.conf is deprecated).
-- Hyprland loads ~/.config/hypr/hyprland.lua and, when present, ignores
-- hyprland.conf entirely. The full API is documented in the shipped stub:
--   $(dirname $(readlink -f $(command -v Hyprland)))/../share/hypr/stubs/hl.meta.lua
--
-- This config is split into modules under conf/. Because Hyprland may reuse
-- the same Lua VM across `hyprctl reload`, we drop our modules from the
-- require cache first so every reload re-executes them (and thus re-registers
-- binds, rules, etc.) instead of returning stale cached tables.

for name in pairs(package.loaded) do
    if name:match("^conf%.") then
        package.loaded[name] = nil
    end
end

require("conf.env")        -- environment variables
require("conf.monitors")   -- monitors + workspaces (host-specific)
require("conf.looknfeel")  -- general / decoration / animations / misc
require("conf.input")      -- keyboard / mouse / touchpad
require("conf.binds")      -- keybinds
require("conf.rules")      -- window rules
require("conf.axshell")    -- Ax-Shell keybinds + helpers
require("conf.autostart")  -- exec-once startup programs
