#!/usr/bin/env bash
# Listens on Hyprland IPC socket2 for:
# 1. openwindow events — hides "is sharing your screen" popups (Chromium/Electron)
# 2. screencast events — turns borders red while screen sharing is active

SHARING_ACTIVE_COLOR="rgb(ff3333)"
SHARING_INACTIVE_COLOR="rgba(ff333366)"

SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

ORIGINAL_ACTIVE=$(hyprctl getoption general:col.active_border -j | jq -r '.str')
ORIGINAL_INACTIVE=$(hyprctl getoption general:col.inactive_border -j | jq -r '.str')
SHARING=0

handle() {
    case $1 in
        openwindow\>\>*)
            # Format: openwindow>>ADDRESS,WORKSPACE,CLASS,TITLE
            local data="${1#openwindow>>}"
            local addr="${data%%,*}"
            local title="${data##*,}"
            if [[ "$title" == *"is sharing your screen."* ]]; then
                hyprctl dispatch movewindowpixel -- -3000 -3000,address:0x"$addr"
            fi
            ;;
        screencast\>\>1,*)
            SHARING=$((SHARING + 1))
            hyprctl keyword general:col.active_border "$SHARING_ACTIVE_COLOR"
            hyprctl keyword general:col.inactive_border "$SHARING_INACTIVE_COLOR"
            ;;
        screencast\>\>0,*)
            SHARING=$((SHARING - 1))
            if [ "$SHARING" -le 0 ]; then
                SHARING=0
                hyprctl keyword general:col.active_border "$ORIGINAL_ACTIVE"
                hyprctl keyword general:col.inactive_border "$ORIGINAL_INACTIVE"
            fi
            ;;
    esac
}

nc -U "$SOCKET" | while read -r line; do
    handle "$line"
done
