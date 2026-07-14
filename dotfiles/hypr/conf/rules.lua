-- =============================================================================
-- Window rules
-- =============================================================================

-- Float the calculator
hl.window_rule({
    name  = "float-calculator",
    match = { class = "^(org.gnome.Calculator)$" },
    float = true,
})

-- Floating kitty
hl.window_rule({
    name  = "float-kitty",
    match = { class = "^(kitty-floating)$" },
    float = true,
})

-- Picture-in-Picture: float, fixed size/position, always on top
hl.window_rule({
    name  = "picture-in-picture",
    match = { title = "^(Picture-in-Picture)$" },
    float = true,
    pin   = true,
    size  = "427 240",
    move  = "1492 839",
})

-- Inhibit idle while a window is fullscreen
hl.window_rule({
    name         = "idle-inhibit-fullscreen",
    match        = { fullscreen = true },
    idle_inhibit = "fullscreen",
})
