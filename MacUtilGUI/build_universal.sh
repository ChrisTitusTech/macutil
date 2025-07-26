#!/bin/bash

# Quick Universal App Builder for MacUtil GUI
# This script creates only the universal app bundle without individual architecture builds

echo "🚀 Building Universal MacUtil GUI App..."
echo

# Configuration
APP_NAME="MacUtilGUI"
BUNDLE_NAME="MacUtil"
BUNDLE_IDENTIFIER="com.macutil.gui"
VERSION="0.2.0"
COPYRIGHT="Copyright © 2025 CT Tech Group LLC. All rights reserved."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Clean previous builds
print_status "Cleaning previous builds..."
dotnet clean -c Release > /dev/null 2>&1
rm -rf ./bin/Release/net9.0/publish/
rm -rf ./dist/
mkdir -p ./dist/

# Restore packages
print_status "Restoring NuGet packages..."
dotnet restore > /dev/null

# Build for Intel x64
print_status "Building Intel x64 binary..."
dotnet publish -c Release -r osx-x64 -p:UseAppHost=true --self-contained true -o ./bin/Release/net9.0/publish/osx-x64/ > /dev/null 2>&1
if [ $? -ne 0 ]; then
    print_error "Intel x64 build failed"
    exit 1
fi

# Build for Apple Silicon ARM64
print_status "Building Apple Silicon ARM64 binary..."
dotnet publish -c Release -r osx-arm64 -p:UseAppHost=true --self-contained true -o ./bin/Release/net9.0/publish/osx-arm64/ > /dev/null 2>&1
if [ $? -ne 0 ]; then
    print_error "Apple Silicon ARM64 build failed"
    exit 1
fi

# Create Universal App Bundle
print_status "Creating Universal App Bundle..."
universal_app="./dist/${BUNDLE_NAME}-Universal.app"
mkdir -p "$universal_app/Contents/MacOS"
mkdir -p "$universal_app/Contents/Resources"

# Create universal binary using lipo
print_status "Merging binaries with lipo..."
lipo -create \
    "./bin/Release/net9.0/publish/osx-x64/$APP_NAME" \
    "./bin/Release/net9.0/publish/osx-arm64/$APP_NAME" \
    -output "$universal_app/Contents/MacOS/$APP_NAME" 2>/dev/null

if [ $? -ne 0 ]; then
    print_error "Failed to create universal binary with lipo"
    exit 1
fi

# Copy dependencies
rsync -a --exclude="$APP_NAME" "./bin/Release/net9.0/publish/osx-x64/" "$universal_app/Contents/MacOS/" 2>/dev/null

# Create Info.plist
cat > "$universal_app/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIconFile</key>
    <string>MacUtilGUI.icns</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_IDENTIFIER</string>
    <key>CFBundleName</key>
    <string>$BUNDLE_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>MacUtil GUI</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>LSMinimumSystemVersion</key>
    <string>11.0</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>MCUT</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>NSRequiresAquaSystemAppearance</key>
    <false/>
    <key>NSHumanReadableCopyright</key>
    <string>$COPYRIGHT</string>
</dict>
</plist>
EOF

# Copy icon
if [ -f "MacUtilGUI.icns" ]; then
    cp "MacUtilGUI.icns" "$universal_app/Contents/Resources/"
fi

# Make executable
chmod +x "$universal_app/Contents/MacOS/$APP_NAME"

# Show results
universal_size=$(du -sh "$universal_app" | cut -f1)
print_success "Universal app created: $universal_app"
print_status "Bundle size: $universal_size"

# Verify architecture
print_status "Verifying universal binary:"
lipo -info "$universal_app/Contents/MacOS/$APP_NAME"

echo
print_success "🎉 Universal build complete!"
print_status "📱 Your app will run on both Intel and Apple Silicon Macs"
