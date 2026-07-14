-- =============================================================================
-- Ax-Shell keybinds + helpers
-- =============================================================================
-- Ax-Shell's NixOS module has keybinds.mode = "disabled" — it does NOT manage
-- these itself, so we own them here. `fabric-cli exec ax-shell '<py>'` drives
-- the shell's "notch" widgets.

local function fabric(code)
    return hl.dsp.exec_cmd("fabric-cli exec ax-shell '" .. code .. "'")
end

-- Clipboard history daemon (required for the cliphist widget)
hl.on("hyprland.start", function()
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)

-- ----- Core functions -----
hl.bind("SUPER + ALT + B", hl.dsp.exec_cmd("pkill -x ax-shell; ax-shell")) -- restart Ax-Shell
hl.bind("SUPER + R",      fabric('notch.open_notch("launcher")'))          -- app launcher
hl.bind("SUPER + D",      fabric('notch.open_notch("dashboard")'))         -- dashboard
hl.bind("SUPER + TAB",    fabric('notch.open_notch("overview")'))          -- overview
hl.bind("SUPER + ESCAPE", fabric('notch.open_notch("power")'))             -- power menu
hl.bind("SUPER + S",      fabric('notch.open_notch("tools")'))             -- toolbox

-- Optional widgets / advanced controls were commented out in the old config;
-- re-enable here as needed, e.g.:
-- hl.bind("SUPER + PERIOD", fabric('notch.open_notch("emoji")'))
-- hl.bind("SUPER + COMMA",  fabric('notch.open_notch("wallpapers")'))
