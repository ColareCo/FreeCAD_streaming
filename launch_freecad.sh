#!/usr/bin/env bash
set -e

DOC="${1:-/home/caduser/sessions/start.FCStd}"

# Start FreeCAD in background
/usr/bin/freecad "$DOC" &

APP_PID=$!

# Give it a moment to create a window
sleep 3

# Maximize the FreeCAD window
wmctrl -r "FreeCAD" -b add,maximized_vert,maximized_horz || true

# Wait for FreeCAD to exit so the session stays alive
wait $APP_PID
