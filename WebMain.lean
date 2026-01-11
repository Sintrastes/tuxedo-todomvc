/-
  Web Main Entry Point

  This is the entry point for the WASM-compiled TodoMVC application.
  It exports functions that can be called from JavaScript.
-/

import LtlFormalVerification.TodoMVC.WebMain

/-- Main entry point for WASM module -/
def main : IO Unit := TodoMVC.WebMain.main

/-- Export functions for JavaScript interop -/

@[export getInitialState]
def exportGetInitialState : String :=
  TodoMVC.WebMain.getInitialState

@[export processAction]
def exportProcessAction (stateJson : String) (actionJson : String) : String :=
  TodoMVC.WebMain.processAction stateJson actionJson

@[export renderState]
def exportRenderState (stateJson : String) : String :=
  TodoMVC.WebMain.renderState stateJson
