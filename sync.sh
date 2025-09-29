#!/bin/bash

# Sync script - applies local changes to EC2 and restarts services

echo "🔄 Syncing configuration to EC2..."

# Copy config files to EC2
scp -i freecad_key.pem dcv.conf ubuntu@3.15.234.4:/tmp/
scp -i freecad_key.pem public.perm ubuntu@3.15.234.4:/tmp/
scp -i freecad_key.pem launch_*.sh ubuntu@3.15.234.4:/tmp/

# Apply changes on EC2
ssh -i freecad_key.pem ubuntu@3.15.234.4 "
sudo cp /tmp/dcv.conf /etc/dcv/dcv.conf
sudo cp /tmp/public.perm /etc/dcv/public.perm
sudo cp /tmp/launch_*.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/launch_*.sh
sudo systemctl restart dcvserver
echo '✅ Configuration updated and DCV restarted'
"

echo "🎯 Test your changes at: https://3.15.234.4:8443"
