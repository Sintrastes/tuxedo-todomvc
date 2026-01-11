/-
  Simplified Lean2Wasm Build Tool

  This version uses your local Lean installation instead of requiring
  a separate WASM toolchain download. It compiles the C files generated
  by the normal Lean build process using Emscripten.

  Usage:
    1. Build your Lean target: `lake build WebMain`
    2. Source emscripten: `source ~/emsdk/emsdk_env.sh`
    3. Run this tool: `lake exe lean2wasm_simple`
-/

import Lean

open Lean System

-- Module to compile
def root : Name := `WebMain

-- Web mode enabled
def web : Bool := true

unsafe def main : IO UInt32 := do
  let outdir : FilePath := ".lake" / "build" / "wasm"

  -- Create output directory
  if ¬ (←FilePath.pathExists outdir) then
    IO.FS.createDirAll outdir
    IO.println s!"Created output directory: {outdir}"

  IO.println "╔════════════════════════════════════════════════╗"
  IO.println "║  Simplified WASM Compilation (Local Toolchain) ║"
  IO.println "╚════════════════════════════════════════════════╝"
  IO.println ""

  -- Get Lean installation directory
  let leanExe ← IO.Process.output {
    cmd := "which"
    args := #["lean"]
  }

  if leanExe.exitCode ≠ 0 then
    IO.println "❌ ERROR: Could not find lean executable"
    return 1

  let leanPath := leanExe.stdout.trim
  IO.println s!"Found Lean: {leanPath}"

  -- Derive Lean installation directory (typically ~/.elan/toolchains/...)
  let leanDir := (FilePath.mk leanPath).parent.get!.parent.get!
  IO.println s!"Lean directory: {leanDir}"

  let includeDir := leanDir / "include"
  let libDir := leanDir / "lib" / "lean"

  -- Verify directories exist
  if ¬(←includeDir.pathExists) then
    IO.println s!"❌ ERROR: Include directory not found: {includeDir}"
    return 1

  if ¬(←libDir.pathExists) then
    IO.println s!"❌ ERROR: Lib directory not found: {libDir}"
    return 1

  IO.println s!"Include: {includeDir}"
  IO.println s!"Lib: {libDir}"
  IO.println ""

  IO.println "Finding C files from Lean build..."

  -- Find compiled C files
  let irPath : FilePath := ".lake" / "build" / "ir"
  let mut cfiles : Array String := #[]

  -- Add main module
  let mainC := irPath / "WebMain.c"
  if ←mainC.pathExists then
    cfiles := cfiles.push mainC.toString
    IO.println s!"  ✓ {mainC}"
  else
    IO.println s!"❌ ERROR: Main C file not found: {mainC}"
    IO.println "Run 'lake build WebMain' first!"
    return 1

  -- Add TodoMVC modules
  let todoMVCPath := irPath / "LtlFormalVerification" / "TodoMVC"
  let moduleNames := #["Spec", "App", "View", "WebMain"]

  for modName in moduleNames do
    let cfile := todoMVCPath / s!"{modName}.c"
    if ←cfile.pathExists then
      cfiles := cfiles.push cfile.toString
      IO.println s!"  ✓ {cfile}"

  -- Add core modules
  let corePath := irPath / "LtlFormalVerification"
  let coreModules := #["LTL", "Coalgebra", "TodoMVC"]

  for modName in coreModules do
    let cfile := corePath / s!"{modName}.c"
    if ←cfile.pathExists then
      cfiles := cfiles.push cfile.toString
      IO.println s!"  ✓ {cfile}"

  IO.println s!"Found {cfiles.size} C files"
  IO.println ""

  if cfiles.isEmpty then
    IO.println "❌ ERROR: No C files found!"
    return 1

  IO.println "Compiling to WebAssembly..."
  IO.println "(This will take 5-10 minutes on first build)"
  IO.println ""

  -- Build emcc command arguments
  let mut args : Array String := #[
    "-o", (outdir / "main.js").toString,
    "-I", includeDir.toString,
    "-L", libDir.toString
  ]

  -- Add all C files
  args := args ++ cfiles

  -- Add Lean libraries
  args := args ++ #[
    "-lInit",
    "-lLean",
    "-lleancpp",
    "-lleanrt"
  ]

  -- Web-specific flags
  if web then
    args := args ++ #[
      "-sMODULARIZE=1",
      "-sEXPORT_NAME=createLeanModule",
      "-sEXPORTED_FUNCTIONS=_lean_initialize,_lean_io_mark_end_initialization,_lean_initialize_runtime_module,_main",
      "-sEXPORTED_RUNTIME_METHODS=ccall,cwrap,UTF8ToString,stringToUTF8,getValue,setValue"
    ]

  -- Common flags for WASM
  args := args ++ #[
    "-sALLOW_MEMORY_GROWTH=1",
    "-sINITIAL_MEMORY=33554432",  -- 32MB initial
    "-sSTACK_SIZE=5242880",        -- 5MB stack
    "-sEXPORT_ALL=0",
    "-sERROR_ON_UNDEFINED_SYMBOLS=0",  -- Lean has some weak symbols
    "-sFILESYSTEM=0",              -- Don't need filesystem
    "-sENVIRONMENT=web",           -- Web-only build
    "-Os",                          -- Optimize for size
    "-flto",                        -- Link-time optimization
    "--no-entry"                    -- We provide main
  ]

  -- Run emcc
  IO.println "Running emcc..."
  let out ← IO.Process.output {
    stdin  := .piped
    stdout := .piped
    stderr := .piped
    cmd    := "emcc"
    args   := args
  }

  -- Show output
  if !out.stdout.isEmpty then
    IO.println "=== STDOUT ==="
    IO.println out.stdout

  if !out.stderr.isEmpty then
    IO.println "=== STDERR ==="
    IO.println out.stderr

  if out.exitCode = 0 then
    IO.println ""
    IO.println "╔════════════════════════════════════════════════╗"
    IO.println "║         ✅ Compilation Successful!              ║"
    IO.println "╚════════════════════════════════════════════════╝"
    IO.println ""
    IO.println "Output files:"
    IO.println s!"  📄 {outdir / "main.js"}"
    IO.println s!"  📦 {outdir / "main.wasm"}"
    IO.println ""

    -- Check file sizes
    let jsSize ← (outdir / "main.js").metadata
    let wasmSize ← (outdir / "main.wasm").metadata
    let jsSizeKB := jsSize.byteSize / 1024
    let wasmSizeKB := wasmSize.byteSize / 1024

    IO.println s!"File sizes:"
    IO.println s!"  main.js:   {jsSizeKB} KB"
    IO.println s!"  main.wasm: {wasmSizeKB} KB"
    IO.println ""
    IO.println "Next: Proceed to Phase 3 (web interface)!"

    return 0
  else
    IO.println ""
    IO.println "╔════════════════════════════════════════════════╗"
    IO.println "║         ❌ Compilation Failed                   ║"
    IO.println "╚════════════════════════════════════════════════╝"
    IO.println ""
    IO.println "Common issues:"
    IO.println "  1. Make sure emscripten is sourced:"
    IO.println "     source ~/emsdk/emsdk_env.sh"
    IO.println "  2. Rebuild Lean targets:"
    IO.println "     lake clean && lake build WebMain"
    IO.println "  3. Check that emcc is in PATH:"
    IO.println "     which emcc"

    return out.exitCode
