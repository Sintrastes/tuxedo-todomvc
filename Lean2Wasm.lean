/-
  Lean2Wasm Build Tool

  This tool compiles Lean 4 code to WebAssembly using Emscripten.
  Based on https://github.com/T-Brick/lean2wasm

  Usage:
    1. First build your Lean target: `lake build WebMain`
    2. Run this tool: `lake exe lean2wasm`
    3. Output will be in `.lake/build/wasm/`
-/

import Lean

open Lean System

-- This is what we want to compile and should contain `main`
def root : Name := `WebMain

-- Is this going to be run on a webpage (i.e. should we MODULARIZE)
def web : Bool := true

unsafe def main : IO UInt32 := do
  let outdir : FilePath := ".lake" / "build" / "wasm"

  -- Create output directory if it doesn't exist
  if ¬ (←FilePath.pathExists outdir) then
    IO.FS.createDirAll outdir
    IO.println s!"Created output directory: {outdir}"

  -- Determine toolchain path
  let wasm_tc := s!"lean-{Lean.versionString}-linux_wasm32"
  let toolchain : FilePath := "toolchains" / wasm_tc

  if ¬ (←FilePath.pathExists toolchain) then
    IO.println "ERROR: Couldn't find WASM toolchain"
    IO.println s!"Expected location: {toolchain}"
    IO.println ""
    IO.println "To download the toolchain:"
    IO.println s!"  mkdir -p toolchains"
    IO.println s!"  cd toolchains"
    IO.println s!"  wget https://github.com/leanprover/lean4/releases/download/v{Lean.versionString}/{wasm_tc}.tar.zst"
    IO.println s!"  tar --zstd -xf {wasm_tc}.tar.zst"
    IO.println s!"  cd .."
    return 1

  IO.println "Finding relevant dependencies..."

  -- Find the compiled C files we need
  let irPath : FilePath := ".lake" / "build" / "ir"

  -- Collect all .c files from the build
  let mut cfiles : Array String := #[]

  -- Add main module C file
  let mainC := irPath / "WebMain.c"
  if ←mainC.pathExists then
    cfiles := cfiles.push mainC.toString
    IO.println s!"Found main: {mainC}"
  else
    IO.println s!"WARNING: Main C file not found: {mainC}"
    IO.println "Did you run 'lake build WebMain' first?"
    return 1

  -- Add all TodoMVC module C files
  let todoMVCPath := irPath / "TuxedoMVC" / "TodoMVC"
  let moduleNames := #["Spec", "App", "View", "WebMain"]

  for modName in moduleNames do
    let cfile := todoMVCPath / s!"{modName}.c"
    if ←cfile.pathExists then
      cfiles := cfiles.push cfile.toString
      IO.println s!"Found module: {cfile}"

  -- Add core TuxedoMVC modules
  let corePath := irPath / "TuxedoMVC"
  let coreModules := #["LTL", "Coalgebra", "TodoMVC"]

  for modName in coreModules do
    let cfile := corePath / s!"{modName}.c"
    if ←cfile.pathExists then
      cfiles := cfiles.push cfile.toString
      IO.println s!"Found core: {cfile}"

  IO.println s!"Found {cfiles.size} C files."

  if cfiles.isEmpty then
    IO.println "ERROR: No C files found. Did you build the project first?"
    return 1

  IO.println ""
  IO.println "Compiling to WebAssembly (this may take a while)..."
  IO.println ""

  -- Build emcc command
  let mut args : Array String := #[
    "-o", outdir / "main.js" |>.toString,
    "-I", toolchain / "include" |>.toString,
    "-L", toolchain / "lib" / "lean" |>.toString
  ]

  -- Add all C files
  args := args ++ cfiles

  -- Add libraries
  args := args ++ #[
    "-lInit",
    "-lLean",
    "-lleancpp",
    "-lleanrt",
    "-sFORCE_FILESYSTEM"
  ]

  -- Add web-specific or node-specific flags
  if web then
    args := args ++ #[
      "-sMODULARIZE",
      "-sEXPORT_NAME=createLeanModule",
      "-sEXPORTED_FUNCTIONS=_lean_initialize,_main",
      "-sEXPORTED_RUNTIME_METHODS=ccall,cwrap,UTF8ToString,stringToUTF8"
    ]
  else
    args := args ++ #["-sNODERAWFS"]

  -- Add common flags
  args := args ++ #[
    "-lnodefs.js",
    "-sEXIT_RUNTIME=0",
    "-sMAIN_MODULE=2",
    "-sLINKABLE=0",
    "-sEXPORT_ALL=0",
    "-sALLOW_MEMORY_GROWTH=1",
    "-sERROR_ON_UNDEFINED_SYMBOLS=0",  -- Allow undefined symbols from Std
    "-fwasm-exceptions",
    "-pthread",
    "-flto",
    "-Os"  -- Optimize for size
  ]

  -- Run emcc
  let out ← IO.Process.output {
    stdin  := .piped
    stdout := .piped
    stderr := .piped
    cmd    := "emcc"
    args   := args
  }

  -- Print output
  if !out.stdout.isEmpty then
    IO.println "=== STDOUT ==="
    IO.println out.stdout

  if !out.stderr.isEmpty then
    IO.println "=== STDERR ==="
    IO.println out.stderr

  if out.exitCode = 0 then
    IO.println ""
    IO.println "✅ Compilation successful!"
    IO.println s!"Output files:"
    IO.println s!"  - {outdir / "main.js"}"
    IO.println s!"  - {outdir / "main.wasm"}"
    return 0
  else
    IO.println ""
    IO.println "❌ Compilation failed!"
    return out.exitCode
