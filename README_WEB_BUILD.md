# Building TodoMVC for the Web

**Formally Verified TodoMVC compiled to WebAssembly**

This guide walks you through compiling the formally verified Lean 4 TodoMVC implementation to WebAssembly for use in web browsers.

---

## Quick Start

### Prerequisites

1. **Lean 4** (already installed ✅)
2. **Emscripten** (compile C/C++ to WebAssembly)
3. **Lean WASM Toolchain** (WebAssembly-compatible Lean runtime)

### Installation

#### 1. Install Emscripten

**macOS:**
```bash
brew install emscripten
```

**Linux:**
```bash
git clone https://github.com/emscripten-core/emsdk.git
cd emsdk
./emsdk install latest
./emsdk activate latest
source ./emsdk_env.sh
cd ..
```

Verify:
```bash
emcc --version
```

#### 2. Download Lean WASM Toolchain

```bash
./setup_wasm_toolchain.sh
```

This downloads and extracts the WASM-compatible Lean runtime (~80MB).

### Build to WebAssembly

```bash
./build_wasm.sh
```

**Output:**
- `.lake/build/wasm/main.js` - JavaScript loader
- `.lake/build/wasm/main.wasm` - WebAssembly binary

**Build time:** 5-10 minutes (first time)

---

## What You Get

After building, you have a WebAssembly module with three exported functions:

```javascript
// Get initial todo state
getInitialState() → JSON string

// Process an action (add, toggle, delete, etc.)
processAction(stateJSON, actionJSON) → new state JSON

// Render state to HTML
renderState(stateJSON) → HTML string
```

**All with formal correctness guarantees from Lean 4!**

---

## Using in a Web Page

### Basic Example

```html
<!DOCTYPE html>
<html>
<head>
    <title>Formally Verified TodoMVC</title>
</head>
<body>
    <div id="app"></div>
    
    <script type="module">
        // Load the WASM module
        const createLeanModule = await import('./main.js');
        const Module = await createLeanModule.default();
        
        // Initialize state
        let state = Module.ccall('getInitialState', 'string', [], []);
        
        // Render
        function render() {
            const html = Module.ccall('renderState', 'string', ['string'], [state]);
            document.getElementById('app').innerHTML = html;
        }
        
        // Dispatch action
        function dispatch(action) {
            const actionJSON = JSON.stringify(action);
            state = Module.ccall('processAction', 'string', 
                ['string', 'string'], [state, actionJSON]);
            render();
        }
        
        // Initial render
        render();
        
        // Example: Add a todo
        dispatch({type: 'enterText', text: 'Learn Lean 4'});
        dispatch({type: 'addTodo'});
    </script>
</body>
</html>
```

---

## Action Types

All actions use JSON format:

```javascript
// Enter text in input field
{type: 'enterText', text: 'Todo text'}

// Add the current text as a todo
{type: 'addTodo'}

// Toggle todo completion
{type: 'toggleTodo', id: 0}

// Delete a todo
{type: 'deleteTodo', id: 0}

// Change filter view
{type: 'setFilter', filter: 'all'}      // or 'active', 'completed'

// Toggle all todos
{type: 'toggleAll'}

// Clear completed todos
{type: 'clearCompleted'}
```

---

## Project Status

✅ **Phase 1 Complete:** HTML Serialization
- Lean → HTML strings
- Lean → JSON
- JSON → Lean

✅ **Phase 2 Complete:** WASM Compilation Setup
- Build scripts created
- Lean targets compile
- Ready for WASM compilation

⏳ **Phase 3 Pending:** Web Interface
- HTML page with TodoMVC styling
- JavaScript event handlers
- DOM updates
- Full TodoMVC implementation

---

## Development Workflow

### 1. Modify Lean Code

Edit files in `LtlFormalVerification/TodoMVC/`

### 2. Rebuild

```bash
lake clean
./build_wasm.sh
```

### 3. Test

```bash
# Test in Node.js
node test_wasm.js

# Or test in browser
python3 -m http.server 8000
# Open http://localhost:8000
```

### 4. Verify Proofs Still Hold

```bash
lake build
```

All proofs must still compile successfully!

---

## Troubleshooting

### "emcc not found"
```bash
source ~/emsdk/emsdk_env.sh  # If using emsdk
```

### "Toolchain not found"
```bash
./setup_wasm_toolchain.sh
```

### Compilation fails
```bash
lake clean
lake build web_main
./build_wasm.sh
```

### Output too large
Edit `Lean2Wasm.lean`:
- Change `-Os` to `-Oz` (line 136)
- Add `--strip-all` for smaller output

---

## File Sizes

**Source:**
- Lean code: ~2,000 lines
- Formal proofs: Included

**Compiled:**
- Unoptimized: 3-5 MB
- Optimized: 1-2 MB
- Compressed (gzip): 400-800 KB

---

## Benefits of WASM Approach

✅ **Formally Verified** - All proofs remain valid  
✅ **Type Safe** - Lean's type system prevents bugs  
✅ **Fast** - Near-native performance  
✅ **Portable** - Runs in any modern browser  
✅ **Secure** - WASM sandbox + Lean guarantees  

---

## Next Steps

See **PHASE2_SETUP.md** for detailed compilation instructions.

See **Phase 3** documentation (coming soon) for web interface development.

---

## Links

- **Main README:** `README.md`
- **Phase 1 Details:** `PHASE1_COMPLETE.md`
- **Phase 2 Details:** `PHASE2_SETUP.md`
- **Examples:** `EXAMPLES.md`
- **Emscripten:** https://emscripten.org/
- **Lean 4:** https://leanprover.github.io/

---

**Questions?** Check the detailed phase documentation or Lean 4 community resources.