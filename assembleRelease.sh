#!/bin/bash
set -e
shopt -s extglob

if [[ ! -e "Package.swift" || ! -e "Calendr.xcodeproj" ]]; then
    echo "❌ This script must be run from the project root directory"
    exit 1
fi

# Build the Binary
swift build -c release

# Configuration
CONFIG_DIR="Calendr/Config"
BUILD_DIR="$(swift build -c release --show-bin-path)"
APP_BUNDLE=".build/Calendr.app"
CONTENTS="$APP_BUNDLE/Contents"

# Clean up and Create Folders
rm -rf "$APP_BUNDLE"
mkdir -p "$CONTENTS/MacOS"
mkdir -p "$CONTENTS/Resources"
mkdir -p "$CONTENTS/Frameworks"

# Move the Binary
cp "$BUILD_DIR/Calendr" "$CONTENTS/MacOS/"

# Move your existing Info.plist
cp "$CONFIG_DIR/Info.plist" "$CONTENTS/Info.plist"

# Move Frameworks (like Sentry)
cp -R "$BUILD_DIR"/*.framework "$CONTENTS/Frameworks/"

# Unpack main bundle resources
cp -R "$BUILD_DIR"/Calendr_Calendr.bundle/!(Images.xcassets|Info.plist) "$CONTENTS/Resources/"

# Move all SPM-generated Bundles
cp -R "$BUILD_DIR"/!(Calendr_Calendr).bundle "$CONTENTS/Resources/"

# --- The "Xcode" Variables --- #
PBXPROJ="Calendr.xcodeproj/project.pbxproj"

get_setting() {
    # Search the file, but ignore any lines that contain 'Test'
    grep "$1 =" "$PBXPROJ" | grep -v "Tests" | head -1 | cut -d'=' -f2 | tr -d '"; '
}

# Extract the values
BUNDLE_ID=$(get_setting "PRODUCT_BUNDLE_IDENTIFIER")
VERSION=$(get_setting "MARKETING_VERSION")
BUILD_NUMBER=$(get_setting "CURRENT_PROJECT_VERSION")
MIN_OS=$(get_setting "MACOSX_DEPLOYMENT_TARGET")

# Path to your packaged plist
PLIST="$CONTENTS/Info.plist"

# Inject using plutil (which is included in Command Line Tools)
echo -e "\n💉 Injecting extracted values: ID=$BUNDLE_ID, Version=$VERSION, Build=$BUILD_NUMBER\n"

plutil -replace CFBundleIdentifier -string "$BUNDLE_ID" "$PLIST"
plutil -replace CFBundleShortVersionString -string "$VERSION" "$PLIST"
plutil -replace CFBundleVersion -string "$BUILD_NUMBER" "$PLIST"
plutil -replace LSMinimumSystemVersion -string "$MIN_OS" "$PLIST"
plutil -replace CFBundleExecutable -string "Calendr" "$PLIST"
plutil -replace CFBundleName -string "Calendr" "$PLIST"
plutil -replace CFBundlePackageType -string "APPL" "$PLIST"
plutil -replace CFBundleIconFile -string "AppIcon" "$PLIST"
plutil -replace CFBundleIconName -string "AppIcon" "$PLIST"

# Compile Assets (only if Xcode is installed)
if xcrun actool --version &>/dev/null; then
    xcrun actool "$BUILD_DIR/Calendr_Calendr.bundle/Images.xcassets" \
        --compile "$CONTENTS/Resources" \
        --platform macosx \
        --minimum-deployment-target "$MIN_OS" \
        --app-icon AppIcon \
        --output-partial-info-plist ".build/asset-info.plist" \
        --output-format human-readable-text \
        > /dev/null
else
    echo -e "⚠️  actool not available (full Xcode required), skipping assets compilation.\n"
fi

echo "✅ $APP_BUNDLE assembled successfully!"
