#!/bin/bash

# DCV Session Manager Script
# Run this ON the EC2 instance to manage DCV sessions

set -e

echo "📺 DCV Session Manager"
echo "===================="
echo ""

# Function to list sessions
list_sessions() {
    echo "📋 Current Active Sessions:"
    echo ""
    SESSIONS=$(sudo dcv list-sessions 2>/dev/null)
    if [ -z "$SESSIONS" ]; then
        echo "   ⚠️  No active sessions found"
        return 1
    else
        echo "$SESSIONS"
        return 0
    fi
}

# Function to get public IP
get_public_ip() {
    PUBLIC_IP=$(curl -s --max-time 5 http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "UNKNOWN")
    echo "$PUBLIC_IP"
}

# Function to create sessions
create_sessions() {
    echo ""
    echo "🎯 Creating DCV Sessions..."
    echo ""
    
    # Check if freecad-test exists
    if sudo dcv list-sessions 2>/dev/null | grep -q "freecad-test"; then
        echo "   ℹ️  freecad-test already exists"
    else
        echo "   📦 Creating freecad-test session..."
        sudo dcv create-session --type virtual --owner caduser --init '/usr/local/bin/launch_freecad.sh' freecad-test
        echo "   ✅ freecad-test created"
    fi
    
    # Check if kicad-test exists
    if sudo dcv list-sessions 2>/dev/null | grep -q "kicad-test"; then
        echo "   ℹ️  kicad-test already exists"
    else
        echo "   📦 Creating kicad-test session..."
        sudo dcv create-session --type virtual --owner caduser --init '/usr/local/bin/launch_kicad.sh' kicad-test
        echo "   ✅ kicad-test created"
    fi
}

# Function to show access URLs
show_access_info() {
    PUBLIC_IP=$(get_public_ip)
    echo ""
    echo "🌐 Access Information:"
    echo "===================="
    if [ "$PUBLIC_IP" = "UNKNOWN" ]; then
        echo "   ⚠️  Could not detect public IP"
        echo "   Check AWS console for your EC2 public IP"
        echo ""
        echo "   URL: https://YOUR_EC2_PUBLIC_IP:8443"
    else
        echo "   URL: https://$PUBLIC_IP:8443"
        echo ""
        echo "   Direct Links:"
        echo "   - FreeCAD: https://$PUBLIC_IP:8443/#freecad-test"
        echo "   - KiCad:   https://$PUBLIC_IP:8443/#kicad-test"
    fi
    echo ""
    echo "   Authentication: None required (automatic login)"
    echo "   Owner: caduser"
}

# Function to restart a session
restart_session() {
    local SESSION_NAME=$1
    echo ""
    echo "🔄 Restarting session: $SESSION_NAME"
    
    # Close existing session
    if sudo dcv list-sessions 2>/dev/null | grep -q "$SESSION_NAME"; then
        echo "   Closing existing session..."
        sudo dcv close-session "$SESSION_NAME"
        sleep 2
    fi
    
    # Recreate based on session type
    if [[ "$SESSION_NAME" == *"freecad"* ]]; then
        echo "   Creating FreeCAD session..."
        sudo dcv create-session --type virtual --owner caduser --init '/usr/local/bin/launch_freecad.sh' "$SESSION_NAME"
    elif [[ "$SESSION_NAME" == *"kicad"* ]]; then
        echo "   Creating KiCad session..."
        sudo dcv create-session --type virtual --owner caduser --init '/usr/local/bin/launch_kicad.sh' "$SESSION_NAME"
    else
        echo "   ❌ Unknown session type: $SESSION_NAME"
        return 1
    fi
    
    echo "   ✅ Session restarted"
}

# Main menu
echo "1. List active sessions"
echo "2. Create missing sessions"
echo "3. Show access information"
echo "4. Restart a session"
echo "5. Do everything (list, create, show info)"
echo ""
read -p "Choose an option (1-5): " CHOICE

case $CHOICE in
    1)
        list_sessions
        ;;
    2)
        create_sessions
        echo ""
        list_sessions
        ;;
    3)
        show_access_info
        ;;
    4)
        echo ""
        echo "Available sessions: freecad-test, kicad-test"
        read -p "Enter session name to restart: " SESSION_NAME
        restart_session "$SESSION_NAME"
        ;;
    5)
        list_sessions
        HAS_SESSIONS=$?
        
        if [ $HAS_SESSIONS -ne 0 ]; then
            create_sessions
        fi
        
        echo ""
        list_sessions
        show_access_info
        ;;
    *)
        echo "❌ Invalid option"
        exit 1
        ;;
esac

echo ""
echo "✨ Done!"

