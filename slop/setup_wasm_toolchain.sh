#!/bin/bash
# Setup script to download the Lean WASM toolchain
# This downloads the WebAssembly-compatible Lean toolchain needed for compilation

set -e

echo "╔═══════════════════════════════════════════════════════╗"
echo "║      Lean WASM Toolchain Setup                         ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

# Detect Lean version
if [ ! -f "lean-toolchain" ]; then
    echo "❌ ERROR: lean-toolchain file not found"
    echo "Please run this script from the project root directory"
    exit 1
fi

LEAN_VERSION=$(cat lean-toolchain | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | sed 's/v//')

if [ -z "$LEAN_VERSION" ]; then
    echo "❌ ERROR: Could not detect Lean version from lean-toolchain"
    exit 1
fi

echo "Detected Lean version: $LEAN_VERSION"
echo ""

# Set up paths
TOOLCHAIN_NAME="lean-${LEAN_VERSION}-linux_wasm32"
TOOLCHAIN_DIR="toolchains"
TOOLCHAIN_PATH="${TOOLCHAIN_DIR}/${TOOLCHAIN_NAME}"
TOOLCHAIN_ARCHIVE="${TOOLCHAIN_NAME}.tar.zst"
DOWNLOAD_URL="https://github.com/leanprover/lean4/releases/download/v${LEAN_VERSION}/${TOOLCHAIN_ARCHIVE}"

# Check if toolchain already exists
if [ -d "$TOOLCHAIN_PATH" ]; then
    echo "✓ Toolchain already exists at: $TOOLCHAIN_PATH"
    echo ""
    echo "To re-download, delete the directory first:"
    echo "  rm -rf $TOOLCHAIN_PATH"
    exit 0
fi

# Create toolchains directory
mkdir -p "$TOOLCHAIN_DIR"
echo "Created directory: $TOOLCHAIN_DIR"
echo ""

# Check if tar supports zstd
if ! tar --version | grep -q "zstd"; then
    echo "⚠️  WARNING: Your tar may not support zstd compression"
    echo "If download fails, install zstd: brew install zstd (macOS) or apt install zstd (Linux)"
    echo ""
fi

# Download toolchain
echo "Downloading WASM toolchain..."
echo "URL: $DOWNLOAD_URL"
echo ""

cd "$TOOLCHAIN_DIR"

if command -v wget &> /dev/null; then
    wget "$DOWNLOAD_URL" -O "$TOOLCHAIN_ARCHIVE"
elif command -v curl &> /dev/null; then
    curl -L "$DOWNLOAD_URL" -o "$TOOLCHAIN_ARCHIVE"
else
    echo "❌ ERROR: Neither wget nor curl found. Please install one of them."
    exit 1
fi

if [ ! -f "$TOOLCHAIN_ARCHIVE" ]; then
    echo "❌ ERROR: Download failed"
    exit 1
fi

echo ""
echo "✓ Download complete"
echo ""

# Extract toolchain
echo "Extracting toolchain..."
tar --zstd -xf "$TOOLCHAIN_ARCHIVE"

if [ $? -ne 0 ]; then
    echo "❌ ERROR: Extraction failed"
    echo ""
    echo "Try manually:"
    echo "  cd $TOOLCHAIN_DIR"
    echo "  tar --zstd -xf $TOOLCHAIN_ARCHIVE"
    exit 1
fi

echo "✓ Extraction complete"
echo ""

# Clean up archive
rm "$TOOLCHAIN_ARCHIVE"
echo "✓ Cleaned up archive file"
echo ""

cd ..

# Verify installation
if [ -d "$TOOLCHAIN_PATH/lib" ] && [ -d "$TOOLCHAIN_PATH/include" ]; then
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║         Toolchain Setup Complete! ✅                   ║"
    echo "╚═══════════════════════════════════════════════════════╝"
    echo ""
    echo "Toolchain installed at: $TOOLCHAIN_PATH"
    echo ""
    echo "Next step: Run ./build_wasm.sh to compile your project"
else
    echo "❌ ERROR: Toolchain installation incomplete"
    echo "Expected directories not found in $TOOLCHAIN_PATH"
    exit 1
fi
