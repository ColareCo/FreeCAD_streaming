#!/usr/bin/env bash
set -e

# Detect current display size dynamically (DO NOT force a specific resolution)
export DISPLAY=:0

# Find xrandr path
XRANDR=$(which xrandr 2>/dev/null || find /usr/bin /bin /usr/X11R6/bin -name xrandr 2>/dev/null | head -1 || echo "xrandr")

# DETECT the current resolution (whatever DCV set it to)
sleep 1
CURRENT_RES=$($XRANDR 2>/dev/null | grep -oP '\d+x\d+' | head -1 || echo "unknown")
echo "📐 Detected X display resolution: $CURRENT_RES (using DCV's dynamic size)" >&2

# Open the ESC Design schematic directly in the schematic editor
SCHEMATIC_PATH="/home/caduser/schematics/escDesign.kicad_sch"

echo "📐 Opening schematic directly: $SCHEMATIC_PATH" >&2

# Launch schematic editor directly with the ESC design
/usr/bin/eeschema "$SCHEMATIC_PATH" &

APP_PID=$!

# Give it a moment to create a window
sleep 3

# AGGRESSIVE maximization - try multiple times with different window names
# Find xdotool path
XDOTOOL=$(which xdotool 2>/dev/null || find /usr/bin /bin -name xdotool 2>/dev/null | head -1 || echo "xdotool")

# Wait a bit longer for schematic editor to fully initialize
sleep 2

# Detect actual screen dimensions dynamically FIRST (before trying to resize)
# Try multiple methods to get display geometry
SCREEN_W=$(xdotool getdisplaygeometry 2>/dev/null | awk '{print $1}' || \
           xrandr 2>/dev/null | grep -oP 'current \d+' | awk '{print $2}' || \
           echo "1920")
SCREEN_H=$(xdotool getdisplaygeometry 2>/dev/null | awk '{print $2}' || \
           xrandr 2>/dev/null | grep -oP 'current \d+ x \d+' | awk '{print $4}' || \
           echo "1080")

echo "🖥️  Detected display size: ${SCREEN_W}x${SCREEN_H}" >&2

# Get window ID early for direct control - search for any window
# KiCad 9.x might use different window titles
WINDOW_ID=$($XDOTOOL search --class "kicad" 2>/dev/null | head -1 || \
            $XDOTOOL search --name "Schematic" 2>/dev/null | head -1 || \
            $XDOTOOL search --name "escDesign" 2>/dev/null | head -1 || \
            $XDOTOOL search --class "eeschema" 2>/dev/null | head -1 || echo "")

if [ -n "$WINDOW_ID" ]; then
    echo "✅ Found schematic editor window ID: $WINDOW_ID" >&2
else
    echo "⚠️  Warning: Could not find window ID, trying name-based maximization" >&2
fi

# AGGRESSIVE window resizing - try FULLSCREEN mode to force fill
echo "🎯 Attempting fullscreen mode to force window to fill display..." >&2

for i in {1..25}; do
    # If we have a window ID, use direct manipulation (most reliable)
    if [ -n "$WINDOW_ID" ]; then
        $XDOTOOL windowactivate "$WINDOW_ID" 2>/dev/null || true
        $XDOTOOL windowmove "$WINDOW_ID" 0 0 2>/dev/null || true
        $XDOTOOL windowsize "$WINDOW_ID" ${SCREEN_W} ${SCREEN_H} 2>/dev/null || true
        # Try F11 fullscreen toggle
        $XDOTOOL key --window "$WINDOW_ID" F11 2>/dev/null || true
    fi
    
    # Also try wmctrl with class and name matching (more permissive)
    wmctrl -x -r "kicad" -b add,maximized_vert,maximized_horz 2>/dev/null || true
    wmctrl -x -r "eeschema" -b add,maximized_vert,maximized_horz 2>/dev/null || true
    wmctrl -r ":ACTIVE:" -b add,maximized_vert,maximized_horz 2>/dev/null || true
    
    # Try removing decorations for more screen space
    wmctrl -x -r "kicad" -b remove,decorations 2>/dev/null || true
    wmctrl -x -r "eeschema" -b remove,decorations 2>/dev/null || true
    
    # Try fullscreen as well
    wmctrl -x -r "kicad" -b add,fullscreen 2>/dev/null || true
    wmctrl -x -r "eeschema" -b add,fullscreen 2>/dev/null || true
    
    sleep 0.1
done

echo "✅ Window resizing attempts complete" >&2

# Wait for schematic editor to exit so the session stays alive
wait $APP_PID
