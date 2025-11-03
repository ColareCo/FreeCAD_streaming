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

# Open the specific ESC Design schematic directly
SCHEMATIC_PATH="/home/caduser/schematics/escDesign.kicad_sch"

echo "📐 Opening schematic: $SCHEMATIC_PATH" >&2

# Launch the schematic editor directly with the ESC design
/usr/bin/eeschema "$SCHEMATIC_PATH" &

APP_PID=$!

# Give it a moment to create a window
sleep 3

# AGGRESSIVE maximization - try multiple times with different window names
# Find xdotool path
XDOTOOL=$(which xdotool 2>/dev/null || find /usr/bin /bin -name xdotool 2>/dev/null | head -1 || echo "xdotool")

# Wait a bit longer for eeschema to fully initialize
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

# Get window ID early for direct control
WINDOW_ID=$($XDOTOOL search --name "eeschema" 2>/dev/null | head -1 || \
            $XDOTOOL search --name "Eeschema" 2>/dev/null | head -1 || \
            $XDOTOOL search --name "Schematic" 2>/dev/null | head -1 || echo "")

if [ -n "$WINDOW_ID" ]; then
    echo "✅ Found eeschema window ID: $WINDOW_ID" >&2
fi

# AGGRESSIVE window resizing - try FULLSCREEN mode to force fill
echo "🎯 Attempting fullscreen mode to force window to fill display..." >&2

for i in {1..20}; do
    # Try fullscreen mode (should force window to fill entire display)
    wmctrl -r "eeschema" -b add,fullscreen 2>/dev/null || \
    wmctrl -r "Eeschema" -b add,fullscreen 2>/dev/null || \
    wmctrl -r "Schematic" -b add,fullscreen 2>/dev/null || true
    
    # Also try removing decorations and setting to fullscreen
    wmctrl -r "eeschema" -b remove,decorated 2>/dev/null || true
    wmctrl -r "Eeschema" -b remove,decorated 2>/dev/null || true
    wmctrl -r "eeschema" -b add,fullscreen 2>/dev/null || true
    wmctrl -r "Eeschema" -b add,fullscreen 2>/dev/null || true
    
    # Use xdotool to send F11 (fullscreen toggle) if window ID found
    if [ -n "$WINDOW_ID" ]; then
        $XDOTOOL windowactivate "$WINDOW_ID" 2>/dev/null || true
        $XDOTOOL key --window "$WINDOW_ID" F11 2>/dev/null || true
        sleep 0.2
        # Also try exact positioning
        $XDOTOOL windowmove "$WINDOW_ID" 0 0 2>/dev/null || true
        $XDOTOOL windowsize "$WINDOW_ID" ${SCREEN_W} ${SCREEN_H} 2>/dev/null || true
    fi
    
    # Fallback: try maximize if fullscreen doesn't work
    wmctrl -r "eeschema" -b add,maximized_vert,maximized_horz 2>/dev/null || \
    wmctrl -r "Eeschema" -b add,maximized_vert,maximized_horz 2>/dev/null || true
    
    sleep 0.15
done

echo "✅ Window resizing attempts complete" >&2

# Wait for the schematic editor to exit so the session stays alive
wait $APP_PID
