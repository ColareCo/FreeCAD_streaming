#!/usr/bin/env bash
set -e

# CRITICAL: Set both virtual session resolution AND display layout to match client viewport
# Virtual session resolution = where apps run (width/height in dcv.conf)
# Display layout = what client sees (set via dcv set-display-layout)
# Both must match for KiCad to fill the screen correctly

export DISPLAY=:0

# Find xdotool path
XDOTOOL=$(which xdotool 2>/dev/null || find /usr/bin /bin -name xdotool 2>/dev/null | head -1 || echo "xdotool")

# Detect actual screen dimensions using xdotool (most reliable in DCV environment)
# This is the resolution of the virtual desktop where applications run
SCREEN_W=$($XDOTOOL getdisplaygeometry 2>/dev/null | awk '{print $1}' || echo "1920")
SCREEN_H=$($XDOTOOL getdisplaygeometry 2>/dev/null | awk '{print $2}' || echo "1080")

echo "🖥️  Detected virtual session resolution: ${SCREEN_W}x${SCREEN_H}" >&2

# CRITICAL: Wait for client to connect and resolution to stabilize before launching KiCad
# Based on AWS DCV docs: "By default, DCV adjusts the remote machine's display resolution 
# to match the client's window size. When the client window is resized, DCV requests the 
# server to change its display resolution accordingly."
# 
# Problem: If we launch KiCad before client connects, it detects wrong resolution
# Solution: Wait for client connection, monitor resolution until stable, THEN launch KiCad

SESSION_ID="kicad-test"

# Wait for session to be fully initialized
echo "⏳ Waiting for DCV session to be ready..." >&2
for i in {1..15}; do
    if dcv describe-session "$SESSION_ID" >/dev/null 2>&1; then
        echo "✅ Session is ready" >&2
        break
    fi
    if [ $i -eq 15 ]; then
        echo "⚠️  Warning: Session may not be ready yet, continuing anyway..." >&2
    else
        sleep 1
    fi
done

# CRITICAL: Wait for client to connect and resolution to stabilize
# When client connects (especially in iframe), DCV automatically adjusts resolution
# We need to wait for this to complete before launching KiCad
# Also, force a minimum width to prevent narrow resolutions that cause black bars
echo "⏳ Waiting for client to connect and resolution to stabilize..." >&2

LAST_RES_W=0
LAST_RES_H=0
STABLE_COUNT=0
MAX_WAIT=60  # Maximum 60 seconds wait
WAIT_COUNT=0
MIN_WIDTH=1600  # Minimum width to prevent narrow resolutions (common browser width)

while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
    # Detect current resolution
    CURRENT_W=$($XDOTOOL getdisplaygeometry 2>/dev/null | awk '{print $1}' || echo "0")
    CURRENT_H=$($XDOTOOL getdisplaygeometry 2>/dev/null | awk '{print $2}' || echo "0")
    
    # Check if resolution changed or stabilized
    if [ "$CURRENT_W" != "0" ] && [ "$CURRENT_H" != "0" ]; then
        # Force minimum width if detected width is too narrow
        if [ "$CURRENT_W" -lt "$MIN_WIDTH" ]; then
            echo "⚠️  Detected narrow resolution ${CURRENT_W}x${CURRENT_H}, forcing minimum width $MIN_WIDTH" >&2
            CURRENT_W=$MIN_WIDTH
            # Force resolution via DCV command
            LAYOUT_FORCE="${CURRENT_W}x${CURRENT_H}+0+0"
            dcv set-display-layout --session "$SESSION_ID" "$LAYOUT_FORCE" 2>/dev/null || true
            sleep 1
            # Re-detect after forcing
            CURRENT_W=$($XDOTOOL getdisplaygeometry 2>/dev/null | awk '{print $1}' || echo "$MIN_WIDTH")
            CURRENT_H=$($XDOTOOL getdisplaygeometry 2>/dev/null | awk '{print $2}' || echo "$CURRENT_H")
        fi
        
        if [ "$CURRENT_W" -eq "$LAST_RES_W" ] && [ "$CURRENT_H" -eq "$LAST_RES_H" ]; then
            STABLE_COUNT=$((STABLE_COUNT + 1))
            # Resolution has been stable for 3 consecutive checks (3 seconds)
            if [ $STABLE_COUNT -ge 3 ]; then
                echo "✅ Resolution stabilized at ${CURRENT_W}x${CURRENT_H}" >&2
                SCREEN_W=$CURRENT_W
                SCREEN_H=$CURRENT_H
                break
            fi
        else
            # Resolution changed, reset stability counter
            STABLE_COUNT=0
            echo "📐 Resolution changed: ${LAST_RES_W}x${LAST_RES_H} -> ${CURRENT_W}x${CURRENT_H}" >&2
            LAST_RES_W=$CURRENT_W
            LAST_RES_H=$CURRENT_H
        fi
    fi
    
    WAIT_COUNT=$((WAIT_COUNT + 1))
    sleep 1
done

if [ $WAIT_COUNT -ge $MAX_WAIT ]; then
    echo "⚠️  Timeout waiting for resolution to stabilize" >&2
    # Use detected resolution or force minimum
    FINAL_W=$($XDOTOOL getdisplaygeometry 2>/dev/null | awk '{print $1}' || echo "$MIN_WIDTH")
    FINAL_H=$($XDOTOOL getdisplaygeometry 2>/dev/null | awk '{print $2}' || echo "1080")
    if [ "$FINAL_W" -lt "$MIN_WIDTH" ]; then
        FINAL_W=$MIN_WIDTH
        echo "⚠️  Forcing minimum width $MIN_WIDTH (was ${FINAL_W})" >&2
    fi
    SCREEN_W=$FINAL_W
    SCREEN_H=$FINAL_H
    echo "⚠️  Using resolution: ${SCREEN_W}x${SCREEN_H}" >&2
fi

# Verify current resolution and enforce minimum width
ACTUAL_W=$($XDOTOOL getdisplaygeometry 2>/dev/null | awk '{print $1}' || echo "$SCREEN_W")
ACTUAL_H=$($XDOTOOL getdisplaygeometry 2>/dev/null | awk '{print $2}' || echo "$SCREEN_H")

# If resolution is still too narrow, force 1920x1080 (common browser/iframe size)
if [ "$ACTUAL_W" -lt "$MIN_WIDTH" ]; then
    echo "⚠️  Resolution ${ACTUAL_W}x${ACTUAL_H} is too narrow, forcing 1920x1080" >&2
    ACTUAL_W=1920
    ACTUAL_H=1080
fi

echo "🖥️  Final virtual resolution: ${ACTUAL_W}x${ACTUAL_H}" >&2

# Set display layout to match the stabilized resolution (with minimum width enforced)
# This ensures client sees the same resolution that apps will run at
LAYOUT="${ACTUAL_W}x${ACTUAL_H}+0+0"
echo "🔧 Setting DCV display layout to match virtual resolution: $LAYOUT" >&2
for i in {1..10}; do
    if dcv set-display-layout --session "$SESSION_ID" "$LAYOUT" 2>/dev/null; then
        echo "✅ Display layout set to $LAYOUT" >&2
        # Verify it was set
        sleep 1
        VERIFY_W=$($XDOTOOL getdisplaygeometry 2>/dev/null | awk '{print $1}' || echo "0")
        if [ "$VERIFY_W" != "0" ] && [ "$VERIFY_W" != "$ACTUAL_W" ]; then
            echo "⚠️  Layout set but resolution mismatch: expected ${ACTUAL_W}, got ${VERIFY_W}" >&2
            if [ $i -lt 10 ]; then
                continue  # Try again
            fi
        fi
        break
    else
        if [ $i -eq 10 ]; then
            echo "⚠️  Warning: Could not set display layout after 10 attempts, but continuing..." >&2
        else
            sleep 0.5
        fi
    fi
done

# Final wait for layout to take effect
sleep 2

# Update SCREEN_W and SCREEN_H to match what we actually set
SCREEN_W=$ACTUAL_W
SCREEN_H=$ACTUAL_H

# Open the ESC Design schematic directly in the schematic editor
SCHEMATIC_PATH="/home/caduser/schematics/escDesign.kicad_sch"

echo "📐 Opening schematic directly: $SCHEMATIC_PATH" >&2

# Launch schematic editor directly with the ESC design
# KiCad will now detect the correct screen size (matching virtual resolution)
/usr/bin/eeschema "$SCHEMATIC_PATH" &

APP_PID=$!

# Give KiCad time to fully initialize and create windows
echo "⏳ Waiting for KiCad to initialize..." >&2
sleep 5

# Re-verify resolution (should still match what we set)
VERIFY_W=$($XDOTOOL getdisplaygeometry 2>/dev/null | awk '{print $1}' || echo "$SCREEN_W")
VERIFY_H=$($XDOTOOL getdisplaygeometry 2>/dev/null | awk '{print $2}' || echo "$SCREEN_H")
echo "🖥️  Verified virtual resolution: ${VERIFY_W}x${VERIFY_H} (expected: ${SCREEN_W}x${SCREEN_H})" >&2

# Use verified resolution for window sizing
ACTUAL_W=$VERIFY_W
ACTUAL_H=$VERIFY_H

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

# Calculate target size - match virtual resolution exactly (no padding needed if resolution matches)
# Use the actual detected size, not padded, since virtual resolution should match display layout
FORCE_W=$ACTUAL_W
FORCE_H=$ACTUAL_H
if [ "$FORCE_W" -eq 0 ] || [ "$FORCE_H" -eq 0 ]; then
    # Fallback to detected size if verification failed
    FORCE_W=$SCREEN_W
    FORCE_H=$SCREEN_H
fi
echo "🔧 Target window size: ${FORCE_W}x${FORCE_H} (matching virtual resolution)" >&2

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
