-- =============================================================================
-- Autostart (exec-once): run these once at Hyprland startup
-- =============================================================================

hl.on("hyprland.start", function()
    -- Export session env into the user D-Bus/systemd activation environment.
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP SSH_AUTH_SOCK")

    -- Wallpaper daemon (required by Ax-Shell)
    hl.exec_cmd("awww-daemon")

    -- Ax-Shell
    hl.exec_cmd("uwsm app -- ax-shell")

    -- Screen-share border indicator (turns borders red while sharing)
    hl.exec_cmd("~/.config/hypr/scripts/screencast-border.sh")
end)
