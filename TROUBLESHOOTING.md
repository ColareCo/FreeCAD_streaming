# Troubleshooting DCV Session Not Filling Iframe

## Problem
The DCV session is not filling the entire iframe space, leaving black borders around the KiCad application.

## Root Causes

The black borders are likely caused by **the DCV web viewer's built-in UI chrome** (top bar showing session information), which cannot be removed through server configuration alone. This is a limitation of the DCV web viewer itself.

## Attempted Solutions

### 1. Resolution Matching
- ✅ Set DCV virtual session resolution to 1920x1080
- ✅ Set iframe dimensions to match
- ✅ Configured xrandr on the EC2 instance to match

**Result**: Improved but still has borders from DCV viewer UI.

### 2. CSS Padding/Margin Removal
- ✅ Removed all padding/margins from iframe containers
- ✅ Set `overflow: hidden` on containers
- ✅ Applied `display: block` to iframe

**Result**: Minimized but DCV viewer UI still present.

### 3. Display Layout Setting
- ✅ Used `dcv set-display-layout kicad-test 1920x1080+0+0`

**Result**: Session resolution matches, but viewer UI chrome persists.

## Current Configuration

- **DCV Session Resolution**: 1920x1080
- **Virtual Display**: 1920x1080 (via xrandr)
- **KiCad Window**: Maximized within session
- **Iframe Settings**: No padding/margins, full width/height

## Possible Solutions (Require Further Investigation)

### Option 1: DCV Native Client (Not Web Viewer)
- Use DCV native client application instead of web viewer
- No UI chrome, true fullscreen
- **Drawback**: Requires client installation, not web-based

### Option 2: Custom DCV Web Viewer Proxy
- Create a proxy that modifies DCV viewer HTML/CSS
- Inject CSS to hide UI elements
- **Complexity**: High, requires proxy server setup

### Option 3: Accept UI Chrome
- The top bar is minimal and doesn't significantly impact usability
- Focus on ensuring KiCad fills the available space below it
- **Best for**: Most use cases

### Option 4: Use Fullscreen API
- Trigger browser fullscreen on the iframe
- May hide DCV viewer UI elements
- **Code**: `iframe.requestFullscreen()`

## Next Steps

1. Try fullscreen API approach (`iframe.requestFullscreen()`)
2. Consider if the current UI chrome is acceptable for your use case
3. Evaluate DCV native client as alternative if web-only is not required
4. Accept the minimal UI chrome as part of the DCV viewer experience

