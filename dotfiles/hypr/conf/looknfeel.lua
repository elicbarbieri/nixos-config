-- =============================================================================
-- Look & feel: general / decoration / animations / misc / render
-- =============================================================================

hl.config({
    general = {
        gaps_in     = 3,
        gaps_out    = 6,
        border_size = 2,
        layout      = "dwindle",
    },

    decoration = {
        rounding = 10,
        blur = {
            enabled = true,
            size    = 3,
            passes  = 1,
        },
    },

    dwindle = {
        preserve_split = true,
    },

    misc = {
        disable_hyprland_logo   = true,
        disable_splash_rendering = true,
        focus_on_activate       = true,
        middle_click_paste      = false,
    },

    xwayland = {
        force_zero_scaling = true,
    },

    render = {
        direct_scanout = false,
    },

    cursor = {
        no_hardware_cursors = 2,
    },

    opengl = {
        nvidia_anti_flicker = true,
    },

    animations = {
        enabled = true,
    },
})

-- Animations (curve + per-leaf speed/curve), migrated from the old
-- `bezier`/`animation =` lines.
hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })

hl.animation({ leaf = "windows",     enabled = true, speed = 5, bezier = "myBezier" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 5, bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border",      enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 6, bezier = "default" })
hl.animation({ leaf = "fade",        enabled = true, speed = 5, bezier = "default" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 4, bezier = "default" })

-- `exec =` (runs on start AND every reload): apply the cursor theme.
hl.exec_cmd('hyprctl setcursor "Simp1e-Mix-Dark" 24')
