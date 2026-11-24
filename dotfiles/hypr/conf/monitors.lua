-- =============================================================================
-- Monitors + workspaces  (host-specific, gated on hostname)
-- =============================================================================
-- This is the whole reason we moved to Lua: one config, real branching.
-- `uname -n` gives the machine hostname; we configure monitors and pin
-- workspaces to the right outputs per host.
--
-- Workspace pinning is desktop-only (see below). Workspaces are never
-- persistent, so empty ones get destroyed on leave (keeps the ax-shell
-- indicator dark when a workspace has no windows).

local host = io.popen("uname -n"):read("*l") or ""

-- Catch-all: any monitor without a specific rule below is still enabled and
-- auto-placed, so a window can never end up on a "dead" display.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-- Pin a single workspace to a monitor. Workspace 1 is the global default.
-- If the monitor is absent, Hyprland relocates the workspace to an available
-- output automatically.
local function pin(workspace, monitor)
    hl.workspace_rule({
        workspace = tostring(workspace),
        monitor   = monitor,
        default   = (workspace == 1) or nil,
    })
end

if host == "elicb-dell-desktop" then
    -- Desktop: two external monitors.
    -- Primary: GIGA-BYTE M27Q (2560x1440@59.94)  |  Secondary: Sceptre F27
    hl.monitor({ output = "DP-1", mode = "2560x1440@59.94", position = "0x0",    scale = 1 })
    local dp3 = { output = "DP-3", mode = "1920x1080@60.00", position = "2560x0", scale = 1 }
    hl.monitor(dp3)

    -- Split workspaces across the two heads: 1-5 on the primary, 6-10 on the
    -- secondary. Only meaningful with two monitors, so desktop-only.
    for i = 1, 5  do pin(i, "DP-1") end
    for i = 6, 10 do pin(i, "DP-3") end

    -- NVIDIA EDID/debugfs workaround: DP-3 needs a disable/re-enable cycle
    -- shortly after startup or it comes up wrong. Desktop-only (no DP-3 on the
    -- laptop, where this used to run pointlessly).
    -- same-output hl.monitor() replaces the prior rule + schedules a monitor reload
    hl.on("hyprland.start", function()
        hl.timer(function()
            hl.monitor({ output = "DP-3", disabled = true })
            hl.timer(function() hl.monitor(dp3) end, { timeout = 1000, type = "oneshot" })
        end, { timeout = 3000, type = "oneshot" })
    end)
else
    -- Laptop (elicb-xps) and any other host: internal display is the anchor,
    -- external monitors auto-place to the right when docked. No workspace
    -- pinning -- all workspaces live wherever you are; move windows by hand.
    hl.monitor({ output = "eDP-1", mode = "preferred",       position = "0x0",       scale = 1 })
    hl.monitor({ output = "DP-1",  mode = "2560x1440@59.94", position = "auto-right", scale = 1 })
    hl.monitor({ output = "DP-3",  mode = "1920x1080@60.00", position = "auto-right", scale = 1 })
end
