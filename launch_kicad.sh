#!/usr/bin/env bash
set -e

# Set display resolution to maximum available
export DISPLAY=:0

# Try to set up a larger virtual display resolution
# This might help with DCV session sizing
xrandr --newmode "2560x1440_60.00" 312.25 2560 2752 3024 3488 1440 1443 1448 1493 -hsync +vsync 2>/dev/null || true
xrandr --addmode Virtual-0 2560x1440_60.00 2>/dev/null || true
xrandr --output Virtual-0 --mode 2560x1440_60.00 2>/dev/null || true

# Alternative: try to set a larger resolution
xrandr --output Virtual-0 --mode 2560x1440 2>/dev/null || true
xrandr --output Virtual-1 --mode 2560x1440 2>/dev/null || true

# Use a fixed project name to avoid multiple projects
PROJECT_NAME="kicad-project"
PROJECT_DIR="/home/caduser/sessions"
PROJECT_PATH="$PROJECT_DIR/$PROJECT_NAME"

# Create sessions directory if it doesn't exist
mkdir -p "$PROJECT_DIR"

# Create new KiCad project first
cd "$PROJECT_DIR"
/usr/bin/kicad --new "$PROJECT_NAME" &

# Give KiCad a moment to create the project files
sleep 5

# Close the main KiCad window (we only want the schematic editor)
pkill -f "kicad.*$PROJECT_NAME" || true
sleep 2

# Now launch the schematic editor directly
/usr/bin/eeschema "$PROJECT_PATH.kicad_sch" &

APP_PID=$!

# Give it a moment to create a window
sleep 3

# Force the schematic editor to be maximized
wmctrl -r "eeschema" -b add,maximized_vert,maximized_horz || \
wmctrl -r "Eeschema" -b add,maximized_vert,maximized_horz || \
wmctrl -r "Schematic" -b add,maximized_vert,maximized_horz || \
wmctrl -r "KiCad" -b add,maximized_vert,maximized_horz || true

# Force specific dimensions to ensure it fills the screen
sleep 1
wmctrl -r "eeschema" -e 0,0,0,1920,1080 || \
wmctrl -r "Eeschema" -e 0,0,0,1920,1080 || \
wmctrl -r "Schematic" -e 0,0,0,1920,1080 || \
wmctrl -r "KiCad" -e 0,0,0,1920,1080 || true

# Wait for the schematic editor to exit so the session stays alive
wait $APP_PID
