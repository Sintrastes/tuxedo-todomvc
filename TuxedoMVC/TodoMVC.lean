/-
  TodoMVC Module

  This is the main module for the TodoMVC implementation.
  It exports all components:
  - Spec: LTL specification translated from Quickstrom
  - App: Implementation as a coalgebra/action system
  - View: Abstract HTML representation and rendering
  - Driver: CLI for interacting with the application
  - WebMain: WASM entry point for web interface
  - Proofs: Formal proofs of specification satisfaction
  - Verification: Runtime verification machinery
-/

import TuxedoMVC.TodoMVC.Spec
import TuxedoMVC.TodoMVC.App
import TuxedoMVC.TodoMVC.View
import TuxedoMVC.TodoMVC.Driver
import TuxedoMVC.TodoMVC.WebMain
import TuxedoMVC.TodoMVC.Proofs
import TuxedoMVC.TodoMVC.Verification
