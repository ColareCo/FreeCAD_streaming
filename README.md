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
├── TROUBLESHOOTING.md        # Troubleshooting guide
├── setup.sh                  # Automated setup script
├── dcv.conf                  # DCV server configuration
├── public.perm               # DCV permissions file
├── launch_freecad.sh         # FreeCAD launch script
├── launch_kicad.sh           # KiCad launch script
├── kicad.json                # KiCad configuration (maximization settings)
├── escDesign.kicad_sch       # Sample KiCad schematic file
└── freecad_key.pem           # SSH key for EC2 access
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
   - **No authentication required** - login happens automatically
   - Choose between FreeCAD or KiCad sessions


## 🌐 Access

### Starting a KiCad Session (For Users)

**Method 1: Access via Web Browser**
1. Navigate to: `https://YOUR_EC2_IP:8443`
2. **No login credentials needed** - access is automatic with no authentication
3. Select an available KiCad session from the list
4. KiCad will launch automatically with the ESC Design schematic

**Method 2: Direct Session URL**
- Use the direct session URL: `https://YOUR_EC2_IP:8443/#kicad-test`
- Opens KiCad immediately without session selection

**Method 3: Iframe Embedding**
- Use the iframe URL in your web application
- See the "Embedding Sessions in Iframes" section below for details

### Authentication
- **Authentication is disabled** (`authentication="none"` in `dcv.conf`)
- No username/password required
- Sessions are public and accessible to anyone with the URL
- **Note**: In production, you may want to enable authentication or use firewall rules to restrict access

### Session Details
- **URL**: `https://YOUR_EC2_IP:8443`
- **Sessions**: Choose between FreeCAD or KiCad
- **Owner**: Sessions run as `caduser` automatically

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

### KiCad Automation Configuration
KiCad streaming is fully automated with the following workflow:

1. **Project Creation**: Automatically creates a new KiCad project
2. **Direct Schematic Editor**: Launches `eeschema` directly (skips main KiCad page)
3. **Automatic Maximization**: Uses multiple window management techniques
4. **Fixed Project Name**: Uses `kicad-project` to avoid duplicates

**Key Components**:
- **Launch Script**: `launch_kicad.sh` - Creates project and launches schematic editor
- **KiCad Config**: `kicad.json` with `"maximized": true` for window state
- **Window Management**: `wmctrl` commands for forced maximization
- **Direct Launch**: `eeschema project.kicad_sch` bypasses main KiCad interface

**Workflow**:
```bash
# 1. Create project
kicad --new kicad-project

# 2. Close main KiCad
pkill -f "kicad.*kicad-project"

# 3. Launch schematic editor directly
eeschema kicad-project.kicad_sch

# 4. Force maximization
wmctrl -r "eeschema" -b add,maximized_vert,maximized_horz
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

## 📱 Embedding Sessions in Iframes

DCV sessions can be embedded in iframes for integration into assessment platforms or web applications.

### Configuration for Iframe Embedding

The DCV server must be configured to allow iframe embedding. This is done in `dcv.conf`:

```ini
[connectivity]
# Allow iframe embedding by removing X-Frame-Options restriction
web-x-frame-options = ""

# Set Content-Security-Policy to allow iframe embedding
# Replace with your actual assessment platform domain for security
web-extra-http-headers = [("Content-Security-Policy", "frame-ancestors *")]
```

**Security Note**: For production, replace `*` with your specific domain:
```ini
web-extra-http-headers = [("Content-Security-Policy", "frame-ancestors https://your-assessment-domain.com https://*.your-assessment-domain.com")]
```

### Applying Configuration

1. **Update the configuration file** on your EC2 instance:
   ```bash
   sudo cp dcv.conf /etc/dcv/dcv.conf
   ```

2. **Restart DCV server**:
   ```bash
   sudo systemctl restart dcvserver
   ```

### Direct Session URL Format

Sessions can be accessed directly using:
```
https://YOUR_EC2_IP:8443/#session-name
```

**Example**: For KiCad session `kicad-test`:
```
https://3.15.234.4:8443/#kicad-test
```

### HTML Iframe Code

Embed the session in your assessment platform using:

```html
<iframe
    src="https://3.15.234.4:8443/#kicad-test"
    allow="microphone; fullscreen; clipboard-read; clipboard-write"
    width="100%"
    height="800px"
    frameborder="0"
    title="KiCad Schematic Editor"
></iframe>
```

**Iframe Attributes**:
- `src`: Direct session URL with `#session-name` format
- `allow`: Permissions for microphone, fullscreen, and clipboard access
- `width`/`height`: Size of the embedded viewer
- `frameborder`: Remove iframe border
- `title`: Accessibility label

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