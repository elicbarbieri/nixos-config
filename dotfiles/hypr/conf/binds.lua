-- =============================================================================
-- Keybinds
-- =============================================================================
-- Key strings use "MOD + MOD + KEY" (the '+' separators are required).
-- Bind option flags map from the old hyprlang bind variants:
--   bindl  -> { locked = true }                (works while screen is locked)
--   bindle -> { locked = true, repeating = true }
--   bindm  -> { mouse = true }                 (mouse move/resize drags)

local mod     = "SUPER"
local browser = "brave"

local exec = hl.dsp.exec_cmd

-- ----- Core window/session actions -----
hl.bind(mod .. " + C",            hl.dsp.window.close())
hl.bind(mod .. " + SHIFT + escape", hl.dsp.exit())
hl.bind(mod .. " + space",        hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + P",            hl.dsp.window.pseudo())
hl.bind(mod .. " + SHIFT + D",    hl.dsp.layout("togglesplit"))
hl.bind(mod .. " + Y",            hl.dsp.window.pin())
hl.bind(mod .. " + G",            hl.dsp.window.center())

-- Fullscreen: toggle / true-fullscreen / maximize
hl.bind(mod .. " + F",            hl.dsp.window.fullscreen())
hl.bind(mod .. " + CONTROL + F",  hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(mod .. " + SHIFT + F",    hl.dsp.window.fullscreen({ mode = "maximized" }))

-- ----- Launchers -----
hl.bind(mod .. " + RETURN",         exec("uwsm-app $(kitty -1)"))
hl.bind(mod .. " + SHIFT + RETURN", exec("uwsm-app $(kitty --class kitty-floating -1)"))
hl.bind(mod .. " + SHIFT + E",      exec("uwsm-app kitty -1 -e yazi"))
hl.bind(mod .. " + W",              exec("uwsm app -- " .. browser))
hl.bind(mod .. " + SHIFT + W",      exec("uwsm app -- " .. browser .. " --private-window"))
hl.bind(mod .. " + M",              exec("uwsm app -- flatpak run com.spotify.Client"))
hl.bind(mod .. " + K",              exec("uwsm app -- slack"))
hl.bind(mod .. " + I",              exec("uwsm app -- " .. browser .. " --app=https://app.super-productivity.com --disable-web-security --disable-features=VizDisplayCompositor"))
hl.bind(mod .. " + E",              exec("uwsm app -- " .. browser .. " --app=https://notion.so --disable-web-security --disable-features=VizDisplayCompositor"))

-- keyd toggle
hl.bind(mod .. " + slash", exec("keyd-toggle"))
hl.bind("F12",             exec("keyd-toggle"), { locked = true })

-- ----- Screenshots (hyprshot) -----
hl.bind("Print",          exec("hyprshot -m output -f Screenshots/$(date +%Y-%m-%d-%H-%M-%S).png"))
hl.bind("SHIFT + Print",  exec("hyprshot -m output --clipboard-only"))
hl.bind(mod .. " + SHIFT + S", exec("hyprshot -m region --clipboard-only"))

-- ----- Lock screen -----
hl.bind(mod .. " + L", exec("hyprlock"))

-- ----- Move focus (arrows) -----
hl.bind(mod .. " + Left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + Right", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + Up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + Down",  hl.dsp.focus({ direction = "down" }))

-- ----- Move window (SHIFT + arrows) -----
hl.bind(mod .. " + SHIFT + Left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + Right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mod .. " + SHIFT + Up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + SHIFT + Down",  hl.dsp.window.move({ direction = "down" }))

-- ----- Resize window (CONTROL + arrows) -----
hl.bind(mod .. " + CONTROL + Left",  hl.dsp.window.resize({ x = -50, y = 0 }))
hl.bind(mod .. " + CONTROL + Right", hl.dsp.window.resize({ x = 50,  y = 0 }))
hl.bind(mod .. " + CONTROL + Up",    hl.dsp.window.resize({ x = 0,   y = -50 }))
hl.bind(mod .. " + CONTROL + Down",  hl.dsp.window.resize({ x = 0,   y = 50 }))

-- ----- Workspaces: switch (mod + N) and move-to (mod + SHIFT + N) -----
for i = 1, 10 do
    local key = i % 10 -- 10 maps to the "0" key
    hl.bind(mod .. " + " .. key,           hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. key,   hl.dsp.window.move({ workspace = i }))
end

-- ----- Cycle workspaces -----
hl.bind(mod .. " + mouse_down",  hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + mouse_up",    hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + SHIFT + Z",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + SHIFT + X",   hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + Z",           hl.dsp.focus({ workspace = "-1" }))
hl.bind(mod .. " + X",           hl.dsp.focus({ workspace = "+1" }))

-- ----- Mouse move/resize drags -----
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ----- Media keys -----
hl.bind("XF86AudioPlay", exec("playerctl play-pause"))
hl.bind("XF86AudioPrev", exec("playerctl previous"))
hl.bind("XF86AudioNext", exec("playerctl next"))
hl.bind("XF86AudioMedia", exec("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioStop",  exec("playerctl stop"),       { locked = true })

hl.bind("XF86AudioRaiseVolume", exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",        exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })

-- ----- Brightness -----
hl.bind("XF86MonBrightnessUp",   exec("brightnessctl set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", exec("brightnessctl set 5%-"), { locked = true, repeating = true })

-- ----- Calculator key -----
hl.bind("XF86Calculator", exec("uwsm app -- gnome-calculator"))

-- ----- Lid switch -----
hl.bind("switch:on:Lid Switch",  exec("hyprlock"),                 { locked = true })
hl.bind("switch:off:Lid Switch", exec("hyprctl dispatch dpms on"), { locked = true })
