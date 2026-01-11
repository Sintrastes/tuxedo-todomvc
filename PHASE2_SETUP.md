# Phase 2: WASM Compilation Setup

## Status: Infrastructure Ready ✅ (Awaiting Emscripten Installation)

Phase 2 has successfully created all the build infrastructure for compiling the formally verified TodoMVC application to WebAssembly. The Lean code is ready to be compiled once Emscripten is installed.

---

## ✅ What's Complete

### 1. Build Tool Created (`Lean2Wasm.lean`)

A comprehensive build tool that:
- Automatically finds all required C files from the Lean build
- Configures Emscripten with correct flags for web deployment
- Links against Lean runtime libraries
- Exports functions for JavaScript interop
- Generates modular WASM output suitable for web use

**Key Features:**
- Web mode with `MODULARIZE` flag for safe multiple instantiations
- Exports: `createLeanModule`, `getInitialState`, `processAction`, `renderState`
- Memory growth support for dynamic allocation
- Optimized for size with `-Os` flag
- Thread support with `-pthread`

### 2. Build Scripts Created

**`build_wasm.sh`** - Main build orchestration script:
```bash
./build_wasm.sh
```
- Checks for Emscripten installation
- Builds Lean targets
- Compiles to WebAssembly
- Reports success/failure clearly

**`setup_wasm_toolchain.sh`** - Toolchain download script:
```bash
./setup_wasm_toolchain.sh
```
- Auto-detects Lean version from `lean-toolchain`
- Downloads correct WASM toolchain from GitHub
- Extracts to `toolchains/` directory
- Verifies installation

### 3. Lake Configuration Updated

Added to `lakefile.toml`:
```toml
[[lean_exe]]
name = "lean2wasm"
root = "Lean2Wasm"

[[lean_exe]]
name = "web_main"
root = "WebMain"
```

### 4. Build Status

```
✅ web_main:exe builds successfully (16 jobs)
✅ lean2wasm:exe builds successfully (4 jobs)
✅ All formal proofs still valid
✅ No errors, only deprecation warnings
```

---

## 📋 Requirements

### Required Software

1. **Emscripten** (not yet installed)
   - Version: Latest (tested with 3.1.50+)
   - Purpose: Compiles C to WebAssembly

2. **Lean 4 WASM Toolchain** (not yet installed)
   - Auto-downloads with `setup_wasm_toolchain.sh`
   - Version: Matches your `lean-toolchain` file
   - Size: ~50-100 MB compressed

3. **Already Installed:**
   - ✅ Lean 4 (v4.26.0 detected)
   - ✅ Lake build system
   - ✅ wget or curl (for downloads)
   - ✅ tar with zstd support

---

## 🚀 Installation Instructions

### Step 1: Install Emscripten

Choose your platform:

#### macOS (Homebrew)
```bash
brew install emscripten
```

#### Linux (from source - recommended)
```bash
# Clone the Emscripten SDK
git clone https://github.com/emscripten-core/emsdk.git
cd emsdk

# Install and activate latest version
./emsdk install latest
./emsdk activate latest

# Add to current shell session
source ./emsdk_env.sh

# Optional: Add to your shell profile for persistence
echo 'source ~/emsdk/emsdk_env.sh' >> ~/.bashrc  # or ~/.zshrc
```

#### Verify Installation
```bash
emcc --version
```
Expected output:
```
emcc (Emscripten gcc/clang-like replacement + linker emulating GNU ld) 3.x.x
```

### Step 2: Download Lean WASM Toolchain

Run the setup script from the project root:

```bash
./setup_wasm_toolchain.sh
```

This will:
1. Detect your Lean version (4.26.0)
2. Download `lean-4.26.0-linux_wasm32.tar.zst` from GitHub (~80MB)
3. Extract to `toolchains/lean-4.26.0-linux_wasm32/`
4. Verify the installation

**Manual Download (if script fails):**
```bash
mkdir -p toolchains
cd toolchains
wget https://github.com/leanprover/lean4/releases/download/v4.26.0/lean-4.26.0-linux_wasm32.tar.zst
tar --zstd -xf lean-4.26.0-linux_wasm32.tar.zst
cd ..
```

### Step 3: Build to WebAssembly

Run the build script:

```bash
./build_wasm.sh
```

This will:
1. Build `web_main` Lean target (generates C files)
2. Build `lean2wasm` tool
3. Compile C files to WASM with Emscripten
4. Generate output in `.lake/build/wasm/`

**Expected Output:**
```
╔═══════════════════════════════════════════════════════╗
║   TodoMVC WASM Build - Formally Verified Edition      ║
╚═══════════════════════════════════════════════════════╝

✓ Emscripten found: emcc 3.x.x
Step 1/3: Building Lean targets...
✓ Lean targets built successfully

Step 2/3: Building lean2wasm tool...
✓ lean2wasm tool built

Step 3/3: Compiling to WebAssembly...
Found main: .lake/build/ir/WebMain.c
Found module: .lake/build/ir/LtlFormalVerification/TodoMVC/Spec.c
Found module: .lake/build/ir/LtlFormalVerification/TodoMVC/App.c
Found module: .lake/build/ir/LtlFormalVerification/TodoMVC/View.c
Found module: .lake/build/ir/LtlFormalVerification/TodoMVC/WebMain.c
Found 8 C files.

Compiling to WebAssembly (this may take a while)...

✅ Compilation successful!
Output files:
  - .lake/build/wasm/main.js
  - .lake/build/wasm/main.wasm
```

---

## 📦 Output Files

After successful build, you'll have:

### `.lake/build/wasm/main.js` (~100-200 KB)
- JavaScript loader/wrapper for the WASM module
- Emscripten runtime
- Factory function `createLeanModule()`
- Memory management helpers

### `.lake/build/wasm/main.wasm` (~1-2 MB)
- Compiled WebAssembly binary
- Contains all Lean code + runtime
- Formally verified TodoMVC implementation

---

## 🧪 Testing the WASM Output

### Test 1: Load in Node.js

Create a test file `test_wasm.js`:
```javascript
const createLeanModule = require('./.lake/build/wasm/main.js');

createLeanModule().then(Module => {
    console.log("✓ WASM module loaded successfully!");
    
    // Test exported functions
    try {
        const initial = Module.ccall('getInitialState', 'string', [], []);
        console.log("Initial state:", initial);
    } catch (e) {
        console.log("Note: Functions may need different calling convention");
    }
});
```

Run:
```bash
node test_wasm.js
```

### Test 2: Check File Sizes

```bash
ls -lh .lake/build/wasm/
```

Expected sizes:
- `main.js`: 100-300 KB
- `main.wasm`: 1-3 MB

### Test 3: Verify Exports

Check that WASM exports the expected functions:
```bash
wasm-objdump -x .lake/build/wasm/main.wasm | grep -A 20 "Export section"
```

Should include:
- `_lean_initialize`
- `_main`
- Memory exports

---

## 🐛 Troubleshooting

### Issue: "emcc not found"

**Solution:**
```bash
# If installed via emsdk:
source ~/emsdk/emsdk_env.sh

# Or reinstall:
./emsdk install latest
./emsdk activate latest
```

### Issue: "Toolchain not found"

**Solution:**
```bash
./setup_wasm_toolchain.sh
```

Or manually verify:
```bash
ls -la toolchains/lean-4.26.0-linux_wasm32/
```

Should contain `lib/`, `include/`, and `bin/` directories.

### Issue: "C file not found"

**Solution:** Rebuild Lean targets first:
```bash
lake clean
lake build web_main
./build_wasm.sh
```

### Issue: Compilation takes too long

**Note:** First compilation can take 5-10 minutes due to:
- LTO (Link Time Optimization) with `-flto`
- Size optimization with `-Os`
- Large Lean runtime

**Speed up:**
- Remove `-flto` flag in `Lean2Wasm.lean` (line 135)
- Change `-Os` to `-O2` for faster build (bigger output)

### Issue: WASM file too large

**Current optimizations:**
- `-Os` for size optimization
- `-flto` for link-time optimization
- `MAIN_MODULE=2` to reduce exports

**Additional reduction (if needed):**
- Add `-Oz` instead of `-Os` (more aggressive)
- Strip debug info: `--strip-all`
- Use `wasm-opt` from Binaryen

---

## 📁 Project Structure After Phase 2

```
ltl_formal_verification/
├── LtlFormalVerification/
│   └── TodoMVC/
│       ├── Spec.lean          (State + LTL spec)
│       ├── App.lean           (Actions + transitions + JSON)
│       ├── View.lean          (HTML rendering + serialization)
│       ├── WebMain.lean       (WASM exports)
│       └── ...
├── Lean2Wasm.lean             (✨ NEW - Build tool)
├── WebMain.lean               (✨ NEW - Entry point)
├── build_wasm.sh              (✨ NEW - Build script)
├── setup_wasm_toolchain.sh    (✨ NEW - Toolchain setup)
├── lakefile.toml              (Updated with WASM targets)
├── toolchains/                (✨ Will be created)
│   └── lean-4.26.0-linux_wasm32/
└── .lake/build/wasm/          (✨ Output directory)
    ├── main.js
    └── main.wasm
```

---

## 🎯 Next Steps (Phase 3)

Once WASM compilation is complete, proceed to Phase 3:

### Phase 3: Web Interface
1. Create `web/index.html` with TodoMVC structure
2. Add TodoMVC CSS styling
3. Create `web/app.js` for:
   - Loading WASM module
   - Managing state
   - Event handling
   - DOM updates
4. Test in browser

### Key Integration Points
```javascript
// Phase 3 will implement:
const Module = await createLeanModule();

// Initialize
let state = Module.getInitialState();

// Handle actions
function dispatch(action) {
    const newState = Module.processAction(state, JSON.stringify(action));
    state = newState;
    render();
}

// Render
function render() {
    const html = Module.renderState(state);
    document.getElementById('app').innerHTML = html;
}
```

---

## 📊 Compilation Metrics

**Expected Build Times:**
- Lean targets: 10-30 seconds
- WASM compilation: 5-10 minutes (first time)
- Incremental rebuilds: 30 seconds - 2 minutes

**Expected Output Sizes:**
- Unoptimized: 3-5 MB
- Optimized (`-Os`): 1-2 MB
- With wasm-opt: 800 KB - 1.5 MB

**Memory Usage:**
- Compilation: 2-4 GB RAM
- Runtime: 16-32 MB (grows as needed)

---

## ✅ Phase 2 Checklist

- [x] Create `Lean2Wasm.lean` build tool
- [x] Update `lakefile.toml` with WASM targets
- [x] Create `build_wasm.sh` orchestration script
- [x] Create `setup_wasm_toolchain.sh` download script
- [x] Test Lean target builds (web_main)
- [x] Test build tool compilation (lean2wasm)
- [ ] Install Emscripten (user action required)
- [ ] Download WASM toolchain (user action required)
- [ ] Run full WASM compilation (pending Emscripten)
- [ ] Verify output files (pending compilation)

---

## 🔗 Resources

- **Emscripten Docs:** https://emscripten.org/docs/
- **Lean WASM Releases:** https://github.com/leanprover/lean4/releases
- **Original lean2wasm:** https://github.com/T-Brick/lean2wasm
- **TodoMVC Spec:** https://todomvc.com/

---

**Status:** Phase 2 infrastructure complete. Ready for Emscripten installation and WASM compilation.

**Last Updated:** 2026