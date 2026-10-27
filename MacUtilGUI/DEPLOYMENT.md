# MacUtil GUI - macOS Deployment Guide

This guide explains how to build and deploy the MacUtil GUI application for macOS.

## 🚀 Quick Start

### Building App Bundles

1. **Create the app icon** (one-time setup, only needed if `MacUtilGUI.icns` is missing):
   ```bash
   ./create_icon_from_logo.sh
   ```
   This converts your `logo.png` into the required `MacUtilGUI.icns` format.

2. **Build macOS app bundles**:
   ```bash
   ./packaging/build_app.sh --universal        # x64 + arm64 in one .app
   ./packaging/build_app.sh                    # current architecture only
   ./packaging/build_app.sh --out ~/Applications
   ```

   `deploy_macos.sh` and `build_universal.sh` are kept as thin wrappers around
   `packaging/build_app.sh` for backwards compatibility.

## 📦 What You Get

After running the packaging script, you'll find in the `./dist/` directory:

- `MacUtil-Universal.app` (with `--universal`) - runs on Intel and Apple Silicon
- `MacUtil-arm64.app` / `MacUtil-x64.app` - single architecture builds
- A `.zip` next to each bundle, produced with `ditto` so the executable bit and
  symlinks survive the download.

Each app bundle is **self-contained** and includes all necessary dependencies.

The script also signs the bundle: ad-hoc (`-`) by default, or with a Developer ID
when `--sign "Developer ID Application: Name (TEAMID)"` is passed, optionally
followed by `--notarize <keychain-profile>`.

> [!IMPORTANT]
> Do not publish single-file bundles. They extract their native libraries into
> `~/.net/<app>/<hash>/` at startup, and on Apple Silicon macOS refuses to load
> those ad-hoc signed copies next to the Developer ID signed host process
> (`libSkiaSharp ... different Team IDs`). See the fsproj comment and the README.

## 🔧 Project Configuration

Your project has been configured with the following macOS-specific properties:

### Bundle Information
- **Bundle Name**: MacUtil
- **Display Name**: MacUtil GUI  
- **Bundle Identifier**: com.macutil.gui
- **Version**: 1.0.0
- **Category**: Utilities
- **Minimum macOS Version**: 10.15 (Catalina)

### Build Features
- ✅ Self-contained deployment
- ✅ Single-file publishing
- ✅ Trimmed assemblies for smaller size
- ✅ Ready-to-run images for faster startup
- ✅ High-resolution display support
- ✅ Custom app icon

## 🎯 Testing Your App

### Basic Testing
```bash
# Test the Intel version
open dist/MacUtil-Intel.app

# Test the Apple Silicon version  
open dist/MacUtil-AppleSilicon.app
```

### On Different Machines
Copy the appropriate `.app` bundle to other Macs and test:
- Intel Macs: Use `MacUtil-Intel.app`
- Apple Silicon Macs: Use `MacUtil-AppleSilicon.app`

## 🔐 Code Signing & Distribution

### For Testing/Development
The unsigned app bundles work fine for testing and development. Users may see a warning about running unsigned software.

### For Public Distribution

#### 1. Code Signing (Required for macOS 10.15+)
```bash
# Update the signing identity in sign_macos.sh
# Then run:
./sign_macos.sh
```

**Prerequisites:**
- Apple Developer Account ($99/year)
- Developer ID Application certificate
- Xcode Command Line Tools

#### 2. Notarization (Required for macOS 10.15+)
After code signing, notarize your app:

```bash
# Create a zip for notarization
ditto -c -k --sequesterRsrc --keepParent dist/MacUtil-Intel.app MacUtil-Intel.zip

# Submit for notarization
xcrun altool --notarize-app -f MacUtil-Intel.zip \
  --primary-bundle-id com.macutil.gui \
  -u your@apple.id \
  -p @keychain:AC_PASSWORD

# Wait for approval, then staple the notarization
xcrun stapler staple dist/MacUtil-Intel.app
```

#### 3. Creating a DMG Installer (Optional)
```bash
# Create a DMG for easy distribution
hdiutil create -volname "MacUtil GUI" -srcfolder dist/MacUtil-Intel.app -ov -format UDZO MacUtil-Intel.dmg
```

## 📱 App Store Distribution

For App Store distribution, additional steps are required:

1. **App Store Certificates**: Use "3rd Party Mac Developer" certificates
2. **Sandbox**: Enable App Sandbox with appropriate entitlements
3. **Provisioning Profile**: Use App Store provisioning profile
4. **Packaging**: Create a `.pkg` file for submission

See `sign_macos.sh` for App Store signing templates.

## 🗂 File Structure

```
MacUtilGUI/
├── MacUtilGUI.fsproj          # Project file (updated with macOS config)
├── Info.plist                 # Bundle information template
├── MacUtilGUI.entitlements   # Code signing entitlements
├── MacUtilGUI.icns           # App icon
├── logo.png                   # Source icon image
├── create_icon_from_logo.sh   # Icon generation script
├── deploy_macos.sh            # Main deployment script
├── sign_macos.sh              # Code signing script
└── dist/                      # Output directory
    ├── MacUtil-Intel.app/     # Intel app bundle
    └── MacUtil-AppleSilicon.app/  # ARM64 app bundle
```

## 🛠 Customization

### Changing App Information
Edit the configuration variables in `deploy_macos.sh`:
```bash
APP_NAME="MacUtilGUI"
BUNDLE_NAME="MacUtil"
BUNDLE_IDENTIFIER="com.macutil.gui"
VERSION="1.0.0"
```

### Custom Icon
Replace `logo.png` with your own image and run:
```bash
./create_icon_from_logo.sh
```

### Bundle Properties
Edit `MacUtilGUI.fsproj` to modify bundle properties like:
- `CFBundleName`
- `CFBundleIdentifier` 
- `CFBundleVersion`

## ❓ Troubleshooting

### App Won't Launch
- Check executable permissions: `chmod +x YourApp.app/Contents/MacOS/MacUtilGUI`
- Verify all dependencies are included in the bundle
- Check Console.app for error messages

### "App is damaged" Error
- App needs to be code signed and notarized
- Try: `xattr -cr YourApp.app` to remove quarantine attributes

### Build Errors
- Ensure .NET 9 is installed
- Run `dotnet restore` before building
- Check that all NuGet packages are restored

## 📋 Requirements

- **Development**: macOS with .NET 9 SDK
- **Target**: macOS 10.15 (Catalina) or later
- **Code Signing**: Xcode Command Line Tools
- **Distribution**: Apple Developer Account (for signing/notarization)

## 🔗 Resources

- [Avalonia macOS Deployment Docs](https://docs.avaloniaui.net/docs/deployment/macOS)
- [Apple Bundle Programming Guide](https://developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFBundles/Introduction/Introduction.html)
- [macOS Code Signing Guide](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)

---

✨ **Your Avalonia F# app is now ready for macOS deployment!** ✨

## 🔐 Signing and notarizing (optional)

`packaging/build_app.sh` signs ad-hoc by default, which is enough for personal
use and for testing: macOS shows the "unidentified developer" dialog and the
user accepts it once (right click → Open, or
`xattr -dr com.apple.quarantine /Applications/MacUtil.app`).

To ship a build that opens without any warning you need an Apple Developer
Program membership and a **Developer ID Application** certificate.

1. Xcode → Settings → Accounts → *Manage Certificates* → `+` →
   **Developer ID Application**. Export it from Keychain Access as `.p12`.
2. Notarization credentials, stored in the keychain once:

   ```bash
   xcrun notarytool store-credentials macutil-notary \
     --apple-id "you@example.com" --team-id TEAMID --password "app-specific-password"
   ```

3. Build, sign and notarize:

   ```bash
   ./packaging/build_app.sh --universal \
     --sign "Developer ID Application: Your Name (TEAMID)" \
     --notarize macutil-notary
   ```

### In GitHub Actions

Add three repository secrets and the release workflow picks them up
automatically (without them the build simply stays ad-hoc signed):

| Secret | Value |
| --- | --- |
| `MACOS_CERT_P12` | `base64 -i cert.p12 \| pbcopy` |
| `MACOS_CERT_PASSWORD` | password used when exporting the `.p12` |
| `MACOS_SIGN_IDENTITY` | `Developer ID Application: Your Name (TEAMID)` |

Notarization is not automated in CI (it needs `notarytool` credentials); run the
command above locally, or add your own `notarytool` step with the App Store
Connect API key.
