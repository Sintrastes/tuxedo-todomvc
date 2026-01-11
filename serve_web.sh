#!/bin/bash
# Serve the TodoMVC web application locally
# Usage: ./serve_web.sh [port]

PORT=${1:-8000}

echo "╔═══════════════════════════════════════════════════════╗"
echo "║   TodoMVC - Formally Verified with Lean 4            ║"
echo "║   Starting Local Web Server                          ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

# Check if docs directory exists
if [ ! -d "docs" ]; then
    echo "❌ ERROR: docs directory not found"
    echo "Please run this script from the project root directory"
    exit 1
fi

# Check if WASM files exist
if [ ! -f "docs/main.wasm" ]; then
    echo "⚠️  WARNING: main.wasm not found in docs/"
    echo ""
    echo "Copying WASM files from .lake/build/wasm/..."
    if [ -f ".lake/build/wasm/main.wasm" ]; then
        cp .lake/build/wasm/main.js .lake/build/wasm/main.wasm docs/
        echo "✓ WASM files copied"
    else
        echo "❌ ERROR: WASM files not built yet"
        echo ""
        echo "Please build the WASM module first:"
        echo "  ./build_wasm.sh"
        exit 1
    fi
    echo ""
fi

echo "Starting HTTP server on port $PORT..."
echo ""
echo "📍 Open your browser to:"
echo "   http://localhost:$PORT"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""
echo "─────────────────────────────────────────────────────"
echo ""

# Change to docs directory
cd docs

# Try different ways to start a server
if command -v python3 &> /dev/null; then
    python3 -m http.server $PORT
elif command -v python &> /dev/null; then
    python -m SimpleHTTPServer $PORT
elif command -v php &> /dev/null; then
    php -S localhost:$PORT
else
    echo "❌ ERROR: No HTTP server available"
    echo ""
    echo "Please install Python 3:"
    echo "  macOS: brew install python3"
    echo "  Linux: apt install python3 or yum install python3"
    echo ""
    echo "Or use any other static file server to serve the 'docs/' directory"
    exit 1
fi
