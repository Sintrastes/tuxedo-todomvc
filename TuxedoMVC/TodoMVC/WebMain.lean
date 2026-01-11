/-
  TodoMVC Web Main Entry Point

  This module provides the WASM-exported functions for the web interface.
  JavaScript will call these functions to:
  - Get initial state
  - Process actions (state transitions)
  - Render state to HTML
-/

import TuxedoMVC.TodoMVC.Types
import TuxedoMVC.TodoMVC.Spec
import TuxedoMVC.TodoMVC.App
import TuxedoMVC.TodoMVC.View

namespace TodoMVC.WebMain

open TodoMVC.Types
open TodoMVC.Spec
open TodoMVC.App
open TodoMVC.View

/-! ## WASM-Exported Functions -/

/-- Get the initial state as a JSON string -/
def getInitialState : String :=
  TodoState.initial.toJson

/-- Process an action and return the new state as JSON
    Takes: current state JSON, action JSON
    Returns: new state JSON (or unchanged state if action invalid)
-/
def processAction (stateJson : String) (actionJson : String) : String :=
  match TodoState.fromJson stateJson with
  | none => stateJson  -- Invalid state, return unchanged
  | some state =>
      match Action.fromJson actionJson with
      | none => stateJson  -- Invalid action, return unchanged
      | some action =>
          match todoActionSystem.transition state action with
          | none => stateJson  -- Action not applicable, return unchanged
          | some newState => newState.toJson

/-- Render a state as HTML string
    Takes: state JSON
    Returns: HTML string
-/
def renderState (stateJson : String) : String :=
  match TodoState.fromJson stateJson with
  | none => "<div class=\"todoapp\"><p>Error: Invalid state</p></div>"
  | some state => Html.toString (View.render state)

end TodoMVC.WebMain
