#!/bin/bash

# CAD Streaming Setup Script
# This script automates the setup of DCV-based CAD streaming on Ubuntu 22.04

set -e

echo "🚀 Starting CAD Streaming Setup..."

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "❌ This script should not be run as root. Please run as a regular user with sudo access."
   exit 1
fi

# Save the repo directory path
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "📁 Repository directory: $REPO_DIR"

# Update system
echo "📦 Updating system packages..."
sudo apt update

# Install required packages
echo "🔧 Installing required packages..."
sudo apt install -y wget curl wmctrl xdotool x11-xserver-utils

# Install CAD tools
echo "🎨 Installing CAD tools..."
sudo apt install -y freecad kicad

# Create caduser
echo "👤 Creating caduser..."
if ! id "caduser" &>/dev/null; then
    sudo useradd -m -s /bin/bash caduser
    echo "caduser:freecad123" | sudo chpasswd
    echo "✅ Created caduser with password: freecad123"
else
    echo "ℹ️  caduser already exists"
fi

# Create sessions directory and schematics directory
sudo -u caduser mkdir -p /home/caduser/sessions
sudo -u caduser mkdir -p /home/caduser/schematics

# Download and install DCV
echo "📥 Downloading DCV..."
cd /tmp
wget https://d1uj6qtbmh3dt5.cloudfront.net/2024.0/Servers/nice-dcv-2024.0-19030-ubuntu2204-x86_64.tgz
tar -xzf nice-dcv-2024.0-19030-ubuntu2204-x86_64.tgz
cd nice-dcv-2024.0-19030-ubuntu2204-x86_64

echo "🔧 Installing DCV packages..."
sudo apt install -y ./nice-dcv-server_*.deb ./nice-dcv-web-viewer_*.deb ./nice-xdcv_*.deb

# Configure DCV
echo "⚙️  Configuring DCV..."
sudo cp "$REPO_DIR/dcv.conf" /etc/dcv/dcv.conf
sudo cp "$REPO_DIR/public.perm" /etc/dcv/public.perm

# Setup launch scripts
echo "📝 Setting up launch scripts..."
sudo cp "$REPO_DIR/launch_freecad.sh" /usr/local/bin/launch_freecad.sh
sudo cp "$REPO_DIR/launch_kicad.sh" /usr/local/bin/launch_kicad.sh
sudo chmod +x /usr/local/bin/launch_*.sh

# Copy schematic files
echo "📐 Setting up schematic files..."
if [ -f "$REPO_DIR/escDesign.kicad_sch" ]; then
    sudo cp "$REPO_DIR/escDesign.kicad_sch" /home/caduser/schematics/
    sudo chown caduser:caduser /home/caduser/schematics/escDesign.kicad_sch
    echo "✅ Copied escDesign.kicad_sch"
    
    # Create KiCad project file for the schematic
    sudo -u caduser touch /home/caduser/schematics/escDesign.kicad_pro
    echo "✅ Created escDesign.kicad_pro project file"
else
    echo "⚠️  Warning: escDesign.kicad_sch not found in repo"
fi

# Create project files
sudo -u caduser touch /home/caduser/sessions/start.FCStd
sudo -u caduser touch /home/caduser/sessions/kicad-project.kicad_pro

# Enable and start DCV
echo "🚀 Starting DCV server..."
sudo systemctl enable --now dcvserver

# Wait for DCV to start
sleep 5

# Create sessions
echo "🎯 Creating DCV sessions..."
sudo dcv create-session --type virtual --owner caduser --init '/usr/local/bin/launch_freecad.sh' freecad-test
sudo dcv create-session --type virtual --owner caduser --init '/usr/local/bin/launch_kicad.sh' kicad-test

# Get public IP (with timeout to prevent hanging)
PUBLIC_IP=$(curl -s --max-time 5 http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "UNABLE_TO_DETECT")

echo ""
echo "🎉 Setup Complete!"
echo ""
echo "📋 Access Information:"
if [ "$PUBLIC_IP" = "UNABLE_TO_DETECT" ]; then
    echo "   ⚠️  Could not auto-detect public IP."
    echo "   Please check your EC2 instance public IP in AWS console."
    echo "   URL: https://YOUR_EC2_PUBLIC_IP:8443"
else
    echo "   URL: https://$PUBLIC_IP:8443"
fi
echo "   Username: caduser"
echo "   Password: freecad123"
echo ""
echo "🎯 Available Sessions:"
echo "   - freecad-test (FreeCAD)"
echo "   - kicad-test (KiCad)"
echo ""
echo "🔧 Management Commands:"
echo "   List sessions: sudo dcv list-sessions"
echo "   Close session: sudo dcv close-session session-name"
echo "   Create session: sudo dcv create-session --type virtual --owner caduser --init '/usr/local/bin/launch_kicad.sh' session-name"
echo ""
echo "✨ Your CAD streaming server is ready!"
