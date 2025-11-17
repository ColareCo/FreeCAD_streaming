#!/usr/bin/env bash
set -e

# Detect current display size dynamically (DO NOT force a specific resolution)
export DISPLAY=:0

# Find xdotool path
XDOTOOL=$(which xdotool 2>/dev/null || find /usr/bin /bin -name xdotool 2>/dev/null | head -1 || echo "xdotool")

# Open the ESC Design schematic directly in the schematic editor
SCHEMATIC_PATH="/home/caduser/schematics/escDesign.kicad_sch"

echo "📐 Opening schematic directly: $SCHEMATIC_PATH" >&2

# Launch schematic editor directly with the ESC design
/usr/bin/eeschema "$SCHEMATIC_PATH" &

APP_PID=$!

# Give KiCad time to fully initialize and create windows
echo "⏳ Waiting for KiCad to initialize..." >&2
sleep 5

# Detect actual screen dimensions using xdotool (most reliable in DCV environment)
SCREEN_W=$($XDOTOOL getdisplaygeometry 2>/dev/null | awk '{print $1}' || echo "1512")
SCREEN_H=$($XDOTOOL getdisplaygeometry 2>/dev/null | awk '{print $2}' || echo "944")

echo "🖥️  Detected display size: ${SCREEN_W}x${SCREEN_H}" >&2

# Find the main schematic editor window - look for visible windows only
# Search by class first, then filter to find the largest visible window with "Schematic" in name
echo "🔍 Searching for schematic editor window..." >&2

# Find all visible eeschema windows
WINDOW_IDS=$($XDOTOOL search --onlyvisible --class "eeschema" 2>/dev/null || echo "")

if [ -z "$WINDOW_IDS" ]; then
    # Fallback: search by class without visibility filter
    WINDOW_IDS=$($XDOTOOL search --class "eeschema" 2>/dev/null || echo "")
    echo "⚠️  No visible windows found, searching all windows..." >&2
fi

WINDOW_ID=""
LARGEST_SIZE=0

# Loop through all found windows to find the main one (largest with "Schematic" in name)
for wid in $WINDOW_IDS; do
    # Get window name and geometry
    WINDOW_NAME=$($XDOTOOL getwindowname "$wid" 2>/dev/null || echo "")
    GEOMETRY=$($XDOTOOL getwindowgeometry "$wid" 2>/dev/null | grep "Geometry" | awk '{print $2}' || echo "0x0")
    
    # Extract width and height from geometry (format: WIDTHxHEIGHT)
    W=$(echo "$GEOMETRY" | cut -d'x' -f1)
    H=$(echo "$GEOMETRY" | cut -d'x' -f2)
    
    # Calculate window area
    SIZE=$((W * H))
    
    # Check if this is likely the main window (has "Schematic" in name and is reasonably large)
    if [[ "$WINDOW_NAME" == *"Schematic"* ]] || [[ "$WINDOW_NAME" == *"escDesign"* ]]; then
        if [ "$SIZE" -gt "$LARGEST_SIZE" ] && [ "$SIZE" -gt 100000 ]; then  # At least 100k pixels
            LARGEST_SIZE=$SIZE
            WINDOW_ID=$wid
            echo "✅ Found candidate window: $wid ($WINDOW_NAME) - ${W}x${H} (area: $SIZE)" >&2
        fi
    fi
done

# If we didn't find one by name, use the largest window
if [ -z "$WINDOW_ID" ]; then
    echo "⚠️  No window found by name, using largest window..." >&2
    for wid in $WINDOW_IDS; do
        GEOMETRY=$($XDOTOOL getwindowgeometry "$wid" 2>/dev/null | grep "Geometry" | awk '{print $2}' || echo "0x0")
        W=$(echo "$GEOMETRY" | cut -d'x' -f1)
        H=$(echo "$GEOMETRY" | cut -d'x' -f2)
        SIZE=$((W * H))
        
        if [ "$SIZE" -gt "$LARGEST_SIZE" ]; then
            LARGEST_SIZE=$SIZE
            WINDOW_ID=$wid
            WINDOW_NAME=$($XDOTOOL getwindowname "$wid" 2>/dev/null || echo "unknown")
            echo "✅ Selected largest window: $wid ($WINDOW_NAME) - ${W}x${H}" >&2
        fi
    done
fi

if [ -z "$WINDOW_ID" ]; then
    echo "❌ ERROR: Could not find schematic editor window!" >&2
    echo "   Available windows:" >&2
    $XDOTOOL search --class "eeschema" 2>/dev/null | while read wid; do
        NAME=$($XDOTOOL getwindowname "$wid" 2>/dev/null || echo "unknown")
        GEOM=$($XDOTOOL getwindowgeometry "$wid" 2>/dev/null | grep "Geometry" | awk '{print $2}' || echo "unknown")
        echo "   Window $wid: $NAME ($GEOM)" >&2
    done
    exit 1
fi

# Verify we can get window geometry
CURRENT_GEOM=$($XDOTOOL getwindowgeometry "$WINDOW_ID" 2>/dev/null | grep "Geometry" | awk '{print $2}' || echo "unknown")
echo "✅ Using window ID: $WINDOW_ID (Current size: $CURRENT_GEOM)" >&2

# Calculate target size - slightly larger than display to ensure full coverage
FORCE_W=$((SCREEN_W + 100))
FORCE_H=$((SCREEN_H + 50))
echo "🔧 Target window size: ${FORCE_W}x${FORCE_H}" >&2

# AGGRESSIVE window resizing using only xdotool (wmctrl doesn't work in DCV)
echo "🎯 Resizing window to fill display..." >&2

for i in {1..40}; do
    # Move window to top-left corner
    $XDOTOOL windowmove "$WINDOW_ID" 0 0 2>/dev/null || true
    
    # Resize window to fill display (with padding)
    $XDOTOOL windowsize "$WINDOW_ID" ${FORCE_W} ${FORCE_H} 2>/dev/null || true
    
    # Every 5 iterations, verify and log current size
    if [ $((i % 5)) -eq 0 ]; then
        CURRENT=$($XDOTOOL getwindowgeometry "$WINDOW_ID" 2>/dev/null | grep "Geometry" | awk '{print $2}' || echo "unknown")
        echo "   Iteration $i: Current size: $CURRENT" >&2
    fi
    
    sleep 0.1
done

# Final verification
FINAL_GEOM=$($XDOTOOL getwindowgeometry "$WINDOW_ID" 2>/dev/null | grep "Geometry" | awk '{print $2}' || echo "unknown")
FINAL_POS=$($XDOTOOL getwindowgeometry "$WINDOW_ID" 2>/dev/null | grep "Position" | awk '{print $2}' || echo "unknown")
echo "✅ Window resizing complete!" >&2
echo "   Final size: $FINAL_GEOM at position $FINAL_POS" >&2
echo "   Target was: ${FORCE_W}x${FORCE_H}" >&2

# Keep the session alive - wait for schematic editor
wait $APP_PID
