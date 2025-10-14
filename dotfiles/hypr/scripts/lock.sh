#!/bin/bash

set -e

SPACE_VIDEO_DIR="$HOME/.config/hypr/assets/animated-lock.mp4"
MONITOR=$(hyprctl monitors -j | jq -r '.[0].name') # Get primary monitor

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] LOCK: $1" >&2
}

cleanup() {
  log "Cleaning up animated lock screen..."

  pkill -f "mpvpaper.*$SELECTED_VIDEO" 2>/dev/null || true
  sleep 0.2

  # Restore static wallpaper if we have one
  if [[ -n "$CURRENT_WALLPAPER" && -f "$CURRENT_WALLPAPER" ]]; then
    log "Restoring wallpaper: $CURRENT_WALLPAPER"
    swww img "$CURRENT_WALLPAPER" --transition-type fade --transition-duration 1 2>/dev/null || true
  fi

  exit 0
}

# Check if we're in low power mode
if [[ "${LOW_POWER_MODE:-0}" == "1" ]]; then
  exec hyprlock
else
  log "Starting animated lock screen"

  trap cleanup SIGTERM SIGINT EXIT

  log "Selected video: $SELECTED_VIDEO"
  log "Target monitor: $MONITOR"

  # Start animated background with mpvpaper
  log "Starting mpvpaper..."
  mpvpaper --layer overlay "$MONITOR" "$SELECTED_VIDEO" &

  log "Starting hyprlock overlay..."
  hyprlock

  # When hyprlock exits, cleanup runs automatically via trap
  log "hyprlock exited, cleaning up..."
fi

