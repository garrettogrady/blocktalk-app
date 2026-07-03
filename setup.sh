#!/bin/bash
set -e

echo "=== BlockTalk Xcode Project Setup ==="
echo ""

# Check if xcodegen is installed
if ! command -v xcodegen &> /dev/null; then
    echo "XcodeGen not found. Installing via Homebrew..."

    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        echo "Error: Homebrew is not installed. Install it from https://brew.sh"
        exit 1
    fi

    brew install xcodegen
    echo "XcodeGen installed successfully."
else
    echo "XcodeGen is already installed: $(xcodegen version)"
fi

echo ""

# Navigate to project directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "Working directory: $SCRIPT_DIR"
echo ""

# Generate the Xcode project
echo "Generating BlockTalk.xcodeproj..."
xcodegen generate

echo ""
echo "=== Setup complete ==="
echo "Open BlockTalk.xcodeproj in Xcode, or run:"
echo "  open BlockTalk.xcodeproj"
