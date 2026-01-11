# GitHub Pages Setup with LFS WASM Files

## The Problem

GitHub Pages has an issue with Git LFS (Large File Storage) files:
- Git LFS stores large files separately and commits a small "pointer" file
- When GitHub Pages serves files, it serves the LFS pointer instead of the actual binary
- The WASM file (`main.wasm`, 48MB) is tracked by LFS
- Browsers receive the pointer text file and fail with "wasm validation error: failed to match magic number"

## The Solution

Instead of trying to remove the file from LFS (which makes pushing impossible due to size limits), we **load the WASM from GitHub's raw URL**, which properly resolves LFS pointers.

```
https://github.com/Sintrastes/tuxedo-todomvc/raw/refs/heads/main/docs/main.wasm
```

When accessed via `/raw/`, GitHub resolves the LFS pointer and serves the actual 48MB binary file.

## How It Works

### 1. Emscripten Configuration

In `index.html`, we configure the Emscripten module before loading `main.js`:

```javascript
var Module = {
    locateFile: function(path, prefix) {
        if (path.endsWith('.wasm')) {
            // Load from raw GitHub URL which resolves LFS
            return 'https://github.com/Sintrastes/tuxedo-todomvc/raw/refs/heads/main/docs/main.wasm';
        }
        return prefix + path;
    }
};
```

### 2. Script Loading Order

```html
<!-- Configure Module first -->
<script>var Module = { ... }</script>

<!-- Load Emscripten loader (uses Module config) -->
<script src="main.js"></script>

<!-- Load application logic -->
<script src="app.js"></script>
```

### 3. WASM Download

When the page loads:
1. `main.js` (Emscripten loader) runs
2. It calls `Module.locateFile('main.wasm')`
3. Gets back the GitHub raw URL
4. Downloads the 48MB WASM file from GitHub
5. Validates and instantiates the WebAssembly module

## Benefits

✅ **No repository size issues** - WASM stays in LFS, not in regular Git objects
✅ **GitHub handles LFS** - Raw URLs properly resolve LFS pointers
✅ **Easy updates** - Just rebuild WASM and commit (stays in LFS automatically)
✅ **Works with GitHub Pages** - No special configuration needed
✅ **No CDN required** - Uses GitHub's infrastructure

## Tradeoffs

⚠️ **Slower first load** - 48MB download from GitHub (not optimized for edge delivery)
⚠️ **Bandwidth from GitHub** - Uses GitHub bandwidth, not GitHub Pages CDN
⚠️ **CORS dependency** - Relies on GitHub allowing cross-origin WASM requests
⚠️ **No offline support** - Requires network access to GitHub

## Setup Instructions

### Initial Setup (Already Done)

1. ✅ `.nojekyll` file in `docs/` (prevents Jekyll processing)
2. ✅ `Module.locateFile` configuration in `index.html`
3. ✅ WASM file in LFS (`docs/main.wasm`)
4. ✅ Error handling and logging in `app.js`

### After Rebuilding WASM

When you rebuild the WASM module:

```bash
# Build Lean code
lake build WebMain

# Compile to WASM
lake exe lean2wasm

# Copy to docs (overwrites LFS file)
cp .lake/build/wasm/main.wasm docs/
cp .lake/build/wasm/main.js docs/

# Commit (LFS handles main.wasm automatically)
git add docs/main.wasm docs/main.js
git commit -m "Update WASM build"
git push
```

The file stays in LFS, and the raw URL will serve the new version.

## Deployment

### GitHub Pages Configuration

1. **Repository Settings** → **Pages**
2. **Source**: Deploy from a branch
3. **Branch**: `main` 
4. **Folder**: `/docs`
5. **Save**

### Verification After Deploy

Visit: `https://sintrastes.github.io/tuxedo-todomvc/`

Check browser console for:
```
=== TodoMVC Initialization Starting ===
✓ createLeanModule found
Initializing Lean WASM module...
Note: WASM file will be loaded from GitHub raw URL (48MB, may take a moment)
✓ Module loaded successfully
```

## Troubleshooting

### Issue: WASM Still Fails to Load

**Check the raw URL directly:**
```
https://github.com/Sintrastes/tuxedo-todomvc/raw/refs/heads/main/docs/main.wasm
```

- Should trigger a download of a 48MB file
- Open in hex editor: should start with `00 61 73 6D` (the WASM magic number)
- If it's a small text file starting with "version https://git-lfs...", LFS isn't properly configured

**Check browser Network tab:**
- Look for request to the raw GitHub URL
- Status should be 200
- Size should be ~48MB
- Content-Type should be `application/wasm` or `application/octet-stream`

### Issue: CORS Error

If you see CORS errors in console:
- GitHub should allow CORS for raw file access
- This usually isn't an issue, but if it happens, you'd need to:
  - Use a proxy service
  - Or host the WASM on a CDN
  - Or configure a GitHub Action to copy WASM to a CORS-enabled location

### Issue: Slow Loading

The 48MB download takes time:
- **First-time users**: 5-30 seconds depending on connection
- **Return visitors**: Should be cached by browser
- **Improvement options**:
  - Use a CDN (Cloudflare, AWS CloudFront)
  - Compress with Brotli/Gzip (GitHub may do this automatically)
  - Show progress bar (can enhance app.js to display download %)
  - Lazy load WASM (use JS fallback initially)

### Issue: File Not Found (404)

If the raw URL returns 404:
- Check that `docs/main.wasm` exists in the `main` branch
- Verify you've pushed the latest commit
- Try the blob URL instead: `/blob/main/` (but this won't work for WASM, just for debugging)

## Alternative Approaches

If this approach doesn't work for you:

### Option 1: CDN Hosting
Upload WASM to Cloudflare R2, AWS S3, or similar:
```javascript
Module.locateFile = function(path) {
    if (path.endsWith('.wasm')) {
        return 'https://your-cdn.com/main.wasm';
    }
    return path;
};
```

### Option 2: GitHub Releases
Upload WASM as a release asset:
```javascript
Module.locateFile = function(path) {
    if (path.endsWith('.wasm')) {
        return 'https://github.com/Sintrastes/tuxedo-todomvc/releases/download/v1.0.0/main.wasm';
    }
    return path;
};
```

### Option 3: Remove from LFS
If you can push large files:
1. Remove from LFS (update `.gitattributes`)
2. Commit as regular binary
3. Serve from GitHub Pages directly

But this increases repo size significantly.

## Performance Optimization Ideas

### Current Setup (Working but Slow)
- ✅ 48MB WASM from GitHub raw URL
- ⏱️ 5-30 second first load

### Future Improvements

1. **Compression**
   - Ensure GitHub serves with gzip/brotli
   - Could reduce to ~15-20MB

2. **Progressive Loading**
   - Show app with JS fallback immediately
   - Load WASM in background
   - Switch to WASM when ready

3. **CDN + Caching**
   - Host WASM on Cloudflare/CloudFront
   - Better global distribution
   - Edge caching

4. **WASM Optimization**
   - Strip more debug info
   - Use `wasm-opt -Oz`
   - Consider code splitting if possible

## Monitoring

To track WASM loading performance, check:

```javascript
// In app.js, the Module.setStatus callback shows:
[WASM] Downloading...
[WASM] Preparing...
✓ Module loaded successfully
```

Add timing logs:
```javascript
const startTime = performance.now();
leanModule = await createLeanModule();
console.log(`WASM loaded in ${(performance.now() - startTime) / 1000}s`);
```

## Summary

This approach:
- ✅ Works with GitHub Pages + LFS
- ✅ No repository size issues
- ✅ Simple to maintain
- ⚠️ Slower than ideal (but functional)

The WASM loads from GitHub's raw URL, which properly resolves the LFS pointer and serves the actual 48MB binary file to browsers.