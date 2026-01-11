# GitHub Pages Deployment Guide

This document explains how to deploy the Tuxedo TodoMVC application to GitHub Pages and troubleshoot common issues.

## Overview

The application is deployed from the `docs/` directory to GitHub Pages. The `docs/` directory contains:

- `index.html` - Main HTML page
- `app.js` - JavaScript application logic
- `main.js` - Emscripten-generated WASM loader (~135 KB)
- `main.wasm` - Compiled Lean 4 code (~48 MB)
- `todomvc.css` - Styling
- `.nojekyll` - Prevents Jekyll processing

## Setup Instructions

### 1. Build the WASM Module

First, build the Lean code and compile it to WebAssembly:

```bash
# Build Lean targets
lake build WebMain

# Compile to WASM
lake exe lean2wasm
```

This creates files in `.lake/build/wasm/`:
- `main.js` - WASM loader
- `main.wasm` - Compiled module

### 2. Copy Files to docs/

Copy the built WASM files to the docs directory:

```bash
cp .lake/build/wasm/main.js .lake/build/wasm/main.wasm docs/
```

### 3. Ensure .nojekyll Exists

GitHub Pages uses Jekyll by default, which ignores files starting with `_`. The WASM loader needs these files, so we disable Jekyll:

```bash
touch docs/.nojekyll
```

### 4. Commit and Push

```bash
git add docs/
git commit -m "Update WASM build for GitHub Pages"
git push
```

### 5. Configure GitHub Pages

In your repository settings:
1. Go to **Settings** → **Pages**
2. Under **Source**, select **Deploy from a branch**
3. Select branch `main` and folder `/docs`
4. Click **Save**

The site will be available at: `https://[username].github.io/[repository]/`

## Common Issues and Solutions

### Issue 1: "Failed to Load Application" Error

**Symptoms:** The page shows a loading spinner, then displays an error message.

**Possible Causes:**

1. **WASM files not deployed**
   - Solution: Ensure `main.js` and `main.wasm` are in the `docs/` directory and committed to git

2. **MIME type issues**
   - GitHub Pages should serve `.wasm` files with `application/wasm` MIME type automatically
   - If not, check your browser's Network tab to see if the file is being served correctly

3. **Missing .nojekyll file**
   - Solution: Create `.nojekyll` in the `docs/` directory

### Issue 2: Long Load Times

**Cause:** The WASM file is approximately 48 MB, which takes time to download.

**Solutions:**
- **Enable compression**: GitHub Pages should serve gzip/brotli compression automatically
- **Add a loading progress bar**: Update `app.js` to show download progress
- **Optimize build**: Use `-Os` flag (already enabled) for size optimization
- **Future improvement**: Split the WASM module or use lazy loading

### Issue 3: CORS Errors

**Cause:** Browser security restrictions when loading WASM from different origins.

**Solution:** GitHub Pages serves everything from the same origin, so this shouldn't be an issue. If you see CORS errors:
- Check that files are actually deployed to GitHub Pages
- Verify the URL matches your GitHub Pages domain

### Issue 4: Module Not Found Error

**Symptoms:** Console shows "createLeanModule is not defined"

**Causes:**
1. `main.js` failed to load before `app.js`
2. `main.js` is not exported correctly

**Solution:**
- Ensure `index.html` loads `main.js` before `app.js`:
  ```html
  <script src="main.js"></script>
  <script src="app.js"></script>
  ```

### Issue 5: Functions Not Exported

**Symptoms:** Application loads but doesn't work correctly, console shows "Lean functions not found"

**Causes:** The Lean functions aren't being exported correctly from the WASM module.

**Current Status:** The application currently uses a JavaScript fallback implementation that mimics the Lean logic. The exported Lean functions (`getInitialState`, `processAction`, `renderState`) exist in the WASM but aren't being called yet.

**To Fix (Future Work):**
1. Update `app.js` to properly call the exported C functions via Emscripten's ccall/cwrap
2. Handle string marshalling between JavaScript and Lean
3. Test the actual Lean implementation vs. the JS fallback

## Debugging Tips

### Check Browser Console

Open the browser's Developer Tools (F12) and check the Console tab for errors:

```javascript
// You should see these logs if everything is working:
=== TodoMVC Initialization Starting ===
✓ createLeanModule found
Initializing Lean WASM module...
✓ Module loaded successfully
```

### Check Network Tab

1. Open Developer Tools → Network tab
2. Refresh the page
3. Verify these files load successfully:
   - `main.js` (should be ~135 KB)
   - `main.wasm` (should be ~48 MB)
   - Both should have status 200

### Test Locally First

Before deploying, test locally:

```bash
./serve_web.sh
```

Then open `http://localhost:8000` in your browser. If it works locally but not on GitHub Pages, the issue is likely deployment-related.

## Optimizing the WASM Size

The current WASM file is quite large (48 MB) because it includes:
- The entire Lean runtime
- All dependencies (LTL, Coalgebra, etc.)
- Debug information

**Future Optimizations:**

1. **Strip debug info** (if not already done):
   ```bash
   wasm-strip main.wasm
   ```

2. **Use wasm-opt** from Binaryen:
   ```bash
   wasm-opt -Oz -o main-optimized.wasm main.wasm
   ```

3. **Lazy loading**: Only load WASM when needed, use JS fallback for initial render

4. **CDN deployment**: Use a CDN for better compression and caching

## Architecture Notes

### Current Implementation

The application works in two modes:

1. **JavaScript Fallback** (currently active):
   - State management in JavaScript
   - Action processing in JavaScript (matching Lean logic)
   - Rendering in JavaScript (matching Lean HTML structure)
   - Lean WASM is loaded but not actively used for logic

2. **Full Lean Integration** (planned):
   - Call Lean's exported functions directly
   - `getInitialState()` → returns JSON
   - `processAction(stateJson, actionJson)` → returns new state JSON
   - `renderState(stateJson)` → returns HTML string

### Why the Fallback?

The JavaScript fallback was implemented because:
1. Emscripten's function export mechanism needs proper configuration
2. String marshalling between JS and Lean requires careful handling
3. The fallback allows the app to work immediately while WASM integration is refined

The formal verification guarantees apply to the Lean code, not the JavaScript fallback. Full integration with Lean is recommended for production use.

## Troubleshooting Checklist

- [ ] `.nojekyll` file exists in `docs/`
- [ ] `main.wasm` and `main.js` are in `docs/` and committed
- [ ] GitHub Pages is configured to deploy from `docs/` folder
- [ ] `index.html` loads `main.js` before `app.js`
- [ ] WASM file size is ~48 MB (not corrupted/truncated)
- [ ] No CORS errors in browser console
- [ ] Browser supports WebAssembly (all modern browsers do)

## Additional Resources

- [Emscripten Documentation](https://emscripten.org/docs/getting_started/index.html)
- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [WebAssembly MDN Guide](https://developer.mozilla.org/en-US/docs/WebAssembly)
- [Lean 4 Manual](https://lean-lang.org/lean4/doc/)

## Contact

If you encounter issues not covered here, please:
1. Check the browser console for detailed error messages
2. Open an issue on GitHub with:
   - Browser version
   - Console logs
   - Network tab screenshot
   - Description of what's not working