#!/usr/bin/env bash
set -e

DOC="${1:-/home/caduser/sessions/kicad-project.kicad_pro}"

# Start KiCad in background
/usr/bin/kicad "$DOC" &

APP_PID=$!

# Give it a moment to create a window
sleep 3

# Maximize the KiCad window
wmctrl -r "KiCad" -b add,maximized_vert,maximized_horz || true

# Wait for KiCad to exit so the session stays alive
wait $APP_PID
