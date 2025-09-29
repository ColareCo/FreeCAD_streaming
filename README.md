# CAD Streaming Infrastructure

This repository contains the configuration and scripts for setting up cloud-based CAD tool streaming using Amazon DCV (Desktop Cloud Visualization).

## 🎯 Overview

This setup enables remote access to CAD applications (FreeCAD, KiCad) through a web browser, allowing users to work with professional CAD tools without installing them locally.

## 🏗️ Architecture

- **EC2 Instance**: Ubuntu 22.04 with DCV server
- **DCV**: Amazon Desktop Cloud Visualization for remote desktop streaming
- **CAD Tools**: FreeCAD (3D CAD) and KiCad (PCB Design)
- **Access**: Web browser-based access with automatic login

## 📁 Project Structure

```
FreeCAD_streaming/
├── README.md                 # This file
├── setup.sh                 # Automated setup script
├── dcv.conf                  # DCV server configuration
├── public.perm               # DCV permissions file
├── launch_freecad.sh         # FreeCAD launch script
├── launch_kicad.sh           # KiCad launch script
├── setup_history.txt         # Original setup commands
├── freecad_key.pem           # SSH key for EC2 access
└── scripts/                  # Automation scripts (future)
```

## 🚀 Quick Start

### Prerequisites
- AWS EC2 instance (Ubuntu 22.04)
- SSH access to the instance
- Domain/IP address for DCV access

### Automated Setup

1. **Clone this repository to your EC2 instance**
   ```bash
   git clone <your-repo-url>
   cd FreeCAD_streaming
   ```

2. **Run the automated setup script**
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

3. **Access your CAD streaming server**
   - URL: `https://YOUR_EC2_IP:8443`
   - No authentication required
   - Choose between FreeCAD or KiCad sessions

### Manual Setup

If you prefer manual setup, follow the detailed steps in the [README.md](README.md) file.

## 🌐 Access

- **URL**: `https://YOUR_EC2_IP:8443`
- **Authentication**: None (automatic login)
- **Sessions**: Choose between FreeCAD or KiCad

## 🔧 Configuration Details

### DCV Configuration (`dcv.conf`)
- **Authentication**: Disabled (`authentication="none"`)
- **Permissions**: Public access enabled
- **Sessions**: Automatic console session creation
- **Port**: 8443 (default)

### Permissions (`public.perm`)
- **Access**: `%any% allow builtin` (anyone can connect)
- **Features**: Full clipboard, file transfer, and command access

### Launch Scripts
- **FreeCAD**: `launch_freecad.sh` - Launches FreeCAD with window maximization
- **KiCad**: `launch_kicad.sh` - Launches KiCad with window maximization

### KiCad Maximization Configuration
KiCad stores its window state in `/home/caduser/.config/kicad/6.0/kicad.json`. To enable automatic maximization:

1. **Manual Setup**: Run KiCad once, resize it manually, then close properly
2. **Edit Config**: Change `"maximized": false` to `"maximized": true` in the JSON file
3. **Automatic**: KiCad will now open maximized on every launch

**Key Setting**:
```json
"window": {
    "maximized": true,
    "pos_x": 0,
    "pos_y": 0,
    "size_x": 1520,
    "size_y": 907
}
```

## 📊 Current Instance Status

- **Instance ID**: `i-0ae2f36310c17a92f`
- **Public IP**: `3.15.234.4`
- **Active Sessions**: `kicad-test` (KiCad only)
- **Status**: Running and accessible

## 🔄 Session Management

### List Sessions
```bash
sudo dcv list-sessions
```

### Create New Session
```bash
sudo dcv create-session --type virtual --owner caduser --init '/usr/local/bin/launch_kicad.sh' session-name
```

### Close Session
```bash
sudo dcv close-session session-name
```

## 🚀 Future Enhancements

- [ ] Dynamic instance provisioning
- [ ] Multi-user session management
- [ ] API endpoints for session control
- [ ] Auto-scaling based on demand
- [ ] Session persistence and cleanup
- [ ] Integration with assessment systems

## 🛠️ Troubleshooting

### Common Issues

1. **"No session available" error**
   - Check if sessions are running: `sudo dcv list-sessions`
   - Restart DCV server: `sudo systemctl restart dcvserver`

2. **Authentication required**
   - Verify `authentication="none"` in `/etc/dcv/dcv.conf`
   - Check permissions file: `cat /etc/dcv/public.perm`

3. **Session limit reached**
   - Close unused sessions: `sudo dcv close-session session-name`
   - Check session limits in DCV configuration

### Logs
```bash
sudo journalctl -u dcvserver -f
```

## 📝 License

This project is for educational and development purposes. Please ensure compliance with software licenses for FreeCAD, KiCad, and DCV.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📞 Support

For issues and questions:
- Check the troubleshooting section
- Review DCV documentation
- Open an issue in this repository