#!/bin/bash

# Script to create macOS app icon from logo.png
# This script creates an iconset and converts it to .icns format

echo "🎨 Creating macOS app icon from logo.png..."

# Check if logo.png exists
if [ ! -f "logo.png" ]; then
    echo "❌ Error: logo.png not found in current directory"
    exit 1
fi

# Create iconset directory
echo "📁 Creating iconset directory..."
rm -rf MacUtilGUI.iconset
mkdir MacUtilGUI.iconset

# Define icon sizes needed for macOS
declare -a sizes=(16 32 128 256 512)
declare -a retina_sizes=(32 64 256 512 1024)

echo "🔄 Generating icon sizes..."

# Generate standard resolution icons
for i in "${!sizes[@]}"; do
    size=${sizes[$i]}
    echo "  Creating ${size}x${size} icon..."
    sips -z $size $size logo.png --out MacUtilGUI.iconset/icon_${size}x${size}.png >/dev/null 2>&1
done

# Generate retina (@2x) resolution icons
for i in "${!sizes[@]}"; do
    size=${sizes[$i]}
    retina_size=${retina_sizes[$i]}
    echo "  Creating ${size}x${size}@2x icon (${retina_size}x${retina_size})..."
    sips -z $retina_size $retina_size logo.png --out MacUtilGUI.iconset/icon_${size}x${size}@2x.png >/dev/null 2>&1
done

# Verify iconset contents
echo "📋 Generated icon files:"
ls -la MacUtilGUI.iconset/

# Convert iconset to icns format
echo "🔨 Converting iconset to .icns format..."
if command -v iconutil >/dev/null 2>&1; then
    iconutil -c icns MacUtilGUI.iconset -o MacUtilGUI.icns
    if [ $? -eq 0 ]; then
        echo "✅ Successfully created MacUtilGUI.icns"
        
        # Show file info
        echo "📊 Icon file info:"
        ls -lh MacUtilGUI.icns
        
        # Cleanup iconset directory
        rm -rf MacUtilGUI.iconset
        echo "🧹 Cleaned up temporary iconset directory"
        
        echo "🎉 App icon creation complete!"
        echo "📝 The MacUtilGUI.icns file is ready to use for your macOS app bundle."
    else
        echo "❌ Error: Failed to convert iconset to icns format"
        exit 1
    fi
else
    echo "❌ Error: iconutil command not found (required for icns conversion)"
    echo "Please run this script on macOS with Xcode command line tools installed"
    exit 1
fi
