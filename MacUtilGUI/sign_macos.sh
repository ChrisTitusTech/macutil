#!/bin/bash

# macOS Code Signing Script for MacUtil GUI
# This script signs your app bundles for distribution outside the App Store

# Configuration - UPDATE THESE VALUES
DEVELOPER_ID="Developer ID Application: CT Tech Group LLC (8ZHX2A9ALF)"
APP_BUNDLE_PATH="./dist/MacUtil-Universal.app"  # Universal app bundle (recommended)
ENTITLEMENTS_FILE="./MacUtilGUI.entitlements"

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

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

echo "🔐 MacUtil GUI Code Signing Script"
echo "=================================="
echo

# Check if app bundle exists
if [ ! -d "$APP_BUNDLE_PATH" ]; then
    print_error "App bundle not found at: $APP_BUNDLE_PATH"
    print_status "Please run ./deploy_macos.sh first to create the app bundle"
    exit 1
fi

# Check if entitlements file exists
if [ ! -f "$ENTITLEMENTS_FILE" ]; then
    print_error "Entitlements file not found at: $ENTITLEMENTS_FILE"
    exit 1
fi

# Check if codesign is available
if ! command -v codesign &> /dev/null; then
    print_error "codesign command not found. Please install Xcode Command Line Tools."
    exit 1
fi

print_status "App bundle: $APP_BUNDLE_PATH"
print_status "Entitlements: $ENTITLEMENTS_FILE"
print_status "Developer ID: $DEVELOPER_ID"
echo

# List available signing identities
print_status "Available signing identities:"
security find-identity -v -p codesigning
echo

print_warning "IMPORTANT: Make sure you have:"
print_warning "1. A valid Developer ID Application certificate in your Keychain"
print_warning "2. Updated the DEVELOPER_ID variable in this script"
print_warning "3. An Apple Developer account for notarization"
print_warning "4. Set up AC_PASSWORD in keychain with:"
print_warning "   security add-generic-password -a 'contact@christitus.com' -s 'AC_PASSWORD' -w"
print_warning "   (it will prompt you to enter your app-specific password securely)"
echo

# Check if AC_PASSWORD is accessible in keychain
print_status "Checking keychain access for AC_PASSWORD..."
if security find-generic-password -a 'contact@christitus.com' -s 'AC_PASSWORD' >/dev/null 2>&1; then
    print_success "AC_PASSWORD found in keychain"
else
    print_error "AC_PASSWORD not found in keychain or keychain is locked"
    print_status "Please ensure the keychain is unlocked and AC_PASSWORD is stored"
    print_status "You can test with: security find-generic-password -a 'contact@christitus.com' -s 'AC_PASSWORD'"
fi
echo

read -p "Do you want to proceed with code signing? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_status "Code signing cancelled"
    exit 0
fi

# Sign all files in the MacOS directory
print_status "Signing all binaries in the app bundle..."
find "$APP_BUNDLE_PATH/Contents/MacOS/" -type f | while read fname; do
    print_status "Signing: $fname"
    codesign --force --timestamp --options=runtime --entitlements "$ENTITLEMENTS_FILE" --sign "$DEVELOPER_ID" "$fname"
    if [ $? -ne 0 ]; then
        print_error "Failed to sign: $fname"
        exit 1
    fi
done

# Sign the app bundle itself
print_status "Signing the app bundle..."
codesign --force --timestamp --options=runtime --entitlements "$ENTITLEMENTS_FILE" --sign "$DEVELOPER_ID" "$APP_BUNDLE_PATH"

if [ $? -eq 0 ]; then
    print_success "App bundle signed successfully!"
    
    # Verify the signature
    print_status "Verifying signature..."
    codesign --verify --verbose "$APP_BUNDLE_PATH"
    
    if [ $? -eq 0 ]; then
        print_success "Signature verification passed!"
        echo
        
        # Ask if user wants to proceed with notarization
        read -p "Do you want to proceed with notarization? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Starting notarization process..."
            
            # Ensure keychain is unlocked
            print_status "Ensuring keychain is unlocked..."
            security unlock-keychain ~/Library/Keychains/login.keychain-db
            
            # Retrieve AC_PASSWORD from keychain (silently)
            print_status "Retrieving app-specific password from keychain..."
            AC_PASSWORD=$(security find-generic-password -a 'contact@christitus.com' -s 'AC_PASSWORD' -w 2>/dev/null)
            if [ $? -ne 0 ] || [ -z "$AC_PASSWORD" ]; then
                print_error "Failed to retrieve AC_PASSWORD from keychain"
                print_status "Please ensure the keychain is unlocked and AC_PASSWORD is stored correctly"
                exit 1
            fi
            print_success "App-specific password retrieved successfully"
            
            # Create zip for notarization
            ZIP_NAME="MacUtil.zip"
            print_status "Creating zip file for notarization: $ZIP_NAME"
            if [ -f "$ZIP_NAME" ]; then
                rm "$ZIP_NAME"
            fi
            ditto -c -k --sequesterRsrc --keepParent "$APP_BUNDLE_PATH" "$ZIP_NAME"
            
            if [ $? -eq 0 ]; then
                print_success "Zip file created successfully!"
                
                # Submit for notarization
                print_status "Submitting for notarization (this may take several minutes)..."
                print_status "You will see progress updates from Apple's notarization service..."
                echo
                
                # Submit for notarization with real-time output
                xcrun notarytool submit "$ZIP_NAME" --apple-id contact@christitus.com --team-id 8ZHX2A9ALF --password "$AC_PASSWORD" --wait
                
                if [ $? -eq 0 ]; then
                    
                    # Staple the notarization
                    print_status "Stapling notarization to app bundle..."
                    xcrun stapler staple "$APP_BUNDLE_PATH"
                    
                    if [ $? -eq 0 ]; then
                        print_success "Notarization stapled successfully!"
                        print_success "App is now ready for distribution! 🚀"
                        echo
                        print_status "Next steps:"
                        echo "1. Test the notarized app on a different Mac"
                        echo "2. Distribute the app bundle: $APP_BUNDLE_PATH"
                    else
                        print_error "Failed to staple notarization"
                        print_status "The app is notarized but stapling failed. You can distribute it anyway."
                    fi
                else
                    print_error "Notarization failed!"
                    print_status "Check your Apple ID credentials and app-specific password"
                    print_status "You can still distribute the signed app, but users may see security warnings"
                fi
                
                # Clear the password variable for security
                unset AC_PASSWORD
                
                # Clean up zip file
                if [ -f "$ZIP_NAME" ]; then
                    rm "$ZIP_NAME"
                    print_status "Cleaned up temporary zip file"
                fi
            else
                print_error "Failed to create zip file for notarization"
            fi
        else
            print_status "Skipping notarization"
            echo
            print_status "🎯 Manual notarization steps (if needed later):"
            echo "1. Create a zip: ditto -c -k --sequesterRsrc --keepParent '$APP_BUNDLE_PATH' MacUtil.zip"
            echo "2. Submit for notarization: xcrun notarytool submit MacUtil.zip --apple-id contact@christitus.com --team-id 8ZHX2A9ALF --password \$(security find-generic-password -a 'contact@christitus.com' -s 'AC_PASSWORD' -w) --wait"
            echo "3. If successful, staple: xcrun stapler staple '$APP_BUNDLE_PATH'"
        fi
        echo
        print_success "Code signing complete! 🔐"
    else
        print_error "Signature verification failed!"
        exit 1
    fi
else
    print_error "Failed to sign app bundle!"
    exit 1
fi
