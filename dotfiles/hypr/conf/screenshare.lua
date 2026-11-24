-- =============================================================================
-- Screen sharing: red borders while any share is live, hide browser share bars
-- =============================================================================

-- Chromium/Electron "<site> is sharing your screen." bar → off-screen
hl.window_rule({
    name  = "hide-screenshare-bar",
    match = { title = ".*is sharing your screen\\.$" },
    float = true,
    move  = "-3000 -3000",
})

-- captured at load (reload mid-share captures red → stuck until next reload)
local idle = {
    active   = hl.get_config("general.col.active_border"),
    inactive = hl.get_config("general.col.inactive_border"),
}
local shares = 0

hl.on("screenshare.state", function(active)
    shares = math.max(0, shares + (active and 1 or -1))
    local live = shares > 0
    hl.config({ general = { col = {
        active_border   = live and "rgb(ff3333)" or idle.active,
        inactive_border = live and "rgba(ff333366)" or idle.inactive,
    } } })
end)
