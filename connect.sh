#!/bin/bash

# SSH Connection Helper Script
# This script helps you connect to the EC2 instance easily

set -e

echo "🔐 FreeCAD Streaming - SSH Connection Helper"
echo ""

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEY_FILE="$SCRIPT_DIR/freecad_key.pem"

# Check if key file exists
if [ ! -f "$KEY_FILE" ]; then
    echo "❌ Error: SSH key not found at $KEY_FILE"
    echo "   Make sure you're running this from the FreeCAD_streaming directory"
    exit 1
fi

# Set proper key permissions
chmod 400 "$KEY_FILE"
echo "✅ SSH key permissions set"

# Default EC2 IP address (can be overridden with command line argument)
DEFAULT_IP="3.15.234.4"

# Use provided IP or default
if [ -z "$1" ]; then
    EC2_IP="$DEFAULT_IP"
    echo "📡 Using default EC2 IP: $EC2_IP"
else
    EC2_IP="$1"
    echo "📡 Using provided EC2 IP: $EC2_IP"
fi

# Validate IP format (basic check)
if [[ ! $EC2_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "❌ Invalid IP address format: $EC2_IP"
    exit 1
fi

echo ""
echo "🚀 Connecting to ubuntu@$EC2_IP..."
echo "   (Press Ctrl+D or type 'exit' to disconnect)"
echo ""

# Connect to EC2
ssh -i "$KEY_FILE" ubuntu@$EC2_IP

echo ""
echo "👋 Disconnected from EC2 instance"

