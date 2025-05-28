# Vector Chat - Windows Installer Guide

## 📦 MSI Installer

The Vector Chat application now includes a Windows MSI installer for easy distribution and installation.

### 🚀 Installation

1. **Download the Installer**
   - The MSI installer is located at: `build/windows/x64/runner/Release/vector.msix`
   - This file can be distributed to users for installation

2. **Install the Application**
   - Double-click the `vector.msix` file
   - Follow the installation wizard
   - The app will be installed and available in the Start Menu

### 🛠️ Building the Installer

To rebuild the MSI installer:

```bash
# 1. Build the Windows app
flutter build windows --release

# 2. Create the MSI installer
dart run msix:create
```

### 📋 Installer Configuration

The installer is configured with the following settings:

- **App Name**: Vector Chat
- **Publisher**: Vector Team
- **Version**: 1.0.0.0
- **Architecture**: x64
- **Capabilities**: Internet, Microphone, Webcam, File Access
- **Icon**: Custom Vector icon

### 🔧 Configuration Details

The installer configuration is defined in `pubspec.yaml`:

```yaml
msix_config:
  display_name: Vector Chat
  publisher_display_name: Vector Team
  identity_name: com.vector.chat
  msix_version: 1.0.0.0
  description: Vector - Modern Chat Application for Windows
  publisher: CN=Vector Team
  logo_path: assets/icons/icon.jpg
  start_menu_icon_path: assets/icons/icon.jpg
  tile_icon_path: assets/icons/icon.jpg
  icons_background_color: transparent
  architecture: x64
  capabilities: 'internetClient,microphone,webcam,picturesLibrary,videosLibrary,documentsLibrary'
  languages: en-us
  store: false
  install_certificate: false
```

### 📁 File Structure

After building, you'll find:
- `vector.exe` - The main executable
- `vector.msix` - The MSI installer package
- Supporting DLL files and assets

### 🎯 Distribution

The `vector.msix` file can be:
- Shared directly with users
- Hosted on a website for download
- Distributed via email or file sharing services
- Used for enterprise deployment

### ⚠️ Requirements

- Windows 10 version 1809 or later
- x64 architecture
- Internet connection for chat functionality

### 🔍 Troubleshooting

If installation fails:
1. Ensure Windows is up to date
2. Check if the app is already installed
3. Run as administrator if needed
4. Verify system meets minimum requirements

---

**Note**: The MSI installer provides a professional installation experience with proper Windows integration, Start Menu shortcuts, and uninstall capabilities.
