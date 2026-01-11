#!/bin/bash
# Build script for compiling TodoMVC to WebAssembly
# Usage: ./build_wasm.sh

set -e  # Exit on error

echo "╔═══════════════════════════════════════════════════════╗"
echo "║   TodoMVC WASM Build - Formally Verified Edition      ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

# Check if emcc is installed
if ! command -v emcc &> /dev/null; then
    echo "❌ ERROR: emcc (Emscripten) not found!"
    echo ""
    echo "Please install Emscripten first:"
    echo "  https://emscripten.org/docs/getting_started/downloads.html"
    echo ""
    echo "Quick install:"
    echo "  git clone https://github.com/emscripten-core/emsdk.git"
    echo "  cd emsdk"
    echo "  ./emsdk install latest"
    echo "  ./emsdk activate latest"
    echo "  source ./emsdk_env.sh"
    exit 1
fi

echo "✓ Emscripten found: $(emcc --version | head -1)"
echo ""

# Step 1: Build Lean targets
echo "Step 1/3: Building Lean targets..."
echo "───────────────────────────────────"
lake build web_main
if [ $? -ne 0 ]; then
    echo "❌ Failed to build Lean targets"
    exit 1
fi
echo "✓ Lean targets built successfully"
echo ""

# Step 2: Build lean2wasm tool
echo "Step 2/3: Building lean2wasm tool..."
echo "─────────────────────────────────────"
lake build lean2wasm
if [ $? -ne 0 ]; then
    echo "❌ Failed to build lean2wasm"
    exit 1
fi
echo "✓ lean2wasm tool built"
echo ""

# Step 3: Compile to WASM
echo "Step 3/3: Compiling to WebAssembly..."
echo "──────────────────────────────────────"
lake exe lean2wasm
if [ $? -ne 0 ]; then
    echo "❌ WASM compilation failed"
    exit 1
fi

echo ""
echo "╔═══════════════════════════════════════════════════════╗"
echo "║              Build Complete! ✅                        ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""
echo "Output files created in: .lake/build/wasm/"
echo "  - main.js    (JavaScript loader)"
echo "  - main.wasm  (WebAssembly module)"
echo ""
echo "Next steps:"
echo "  1. Create web interface (HTML/CSS/JS)"
echo "  2. Load the WASM module in your webpage"
echo "  3. Call the exported functions:"
echo "     - getInitialState()"
echo "     - processAction(state, action)"
echo "     - renderState(state)"
echo ""
