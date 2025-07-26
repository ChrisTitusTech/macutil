#!/bin/bash

# Create a simple app icon using built-in macOS tools
# This creates a basic placeholder icon that can be replaced later

echo "Creating basic app icon..."

# Create iconset directory
mkdir -p temp_iconset.iconset

# Create a simple colored square using built-in tools
# This uses the 'sips' command to create basic PNG images
for size in 16 32 128 256 512; do
    # Create a colored square - you can customize the color
    /usr/bin/python3 -c "
from PIL import Image
import sys

try:
    # Create a simple colored square
    size = $size
    img = Image.new('RGB', (size, size), color='#4A90E2')  # Nice blue color
    img.save('temp_iconset.iconset/icon_${size}x${size}.png')
    print(f'Created {size}x{size} icon')
except ImportError:
    print('PIL not available, using system approach')
    # Alternative using system tools
    # This creates a simple solid color image
    exit(1)
" 2>/dev/null || {
    # Fallback: copy a system icon as template
    if [ -f "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericApplicationIcon.icns" ]; then
        echo "Using system generic icon as template..."
        cp "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericApplicationIcon.icns" MacUtilGUI.icns
        exit 0
    fi
}
done

# Create high-resolution versions
for size in 32 64 256 512 1024; do
    if [ -f "temp_iconset.iconset/icon_${size}x${size}.png" ]; then
        cp "temp_iconset.iconset/icon_${size}x${size}.png" "temp_iconset.iconset/icon_${size}x${size}@2x.png"
    fi
done

# Convert to icns format
if command -v iconutil >/dev/null 2>&1; then
    iconutil -c icns temp_iconset.iconset -o MacUtilGUI.icns
    echo "✅ Created MacUtilGUI.icns"
else
    echo "⚠️  iconutil not found, copying system icon instead"
    cp "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericApplicationIcon.icns" MacUtilGUI.icns
fi

# Cleanup
rm -rf temp_iconset.iconset

echo "Icon creation complete!"
