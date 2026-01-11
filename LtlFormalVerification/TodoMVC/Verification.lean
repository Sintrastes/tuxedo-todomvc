/-
  TodoMVC Runtime Verification

  This module provides runtime verification machinery for checking that
  traces of TodoMVC executions satisfy the invariants.
-/

import LtlFormalVerification.TodoMVC.Spec
import LtlFormalVerification.TodoMVC.App

namespace TodoMVC.Verification

open TodoMVC.Spec
open TodoMVC.App

/-! ## Runtime Invariant Checking -/

/-- Check if state satisfies invariant (decidable version) -/
def checkInvariant (s : TodoState) : Bool :=
  s.totalItems = 0 || s.selectedFilter.isSome

/-! ## Trace Recording -/

/-- Record an execution trace for verification -/
structure ExecutionTrace where
  states : List TodoState
  actions : List Action
  deriving Repr

/-- Verify that a recorded trace satisfies the invariant -/
def verifyTrace (trace : ExecutionTrace) : Bool :=
  trace.states.all checkInvariant

/-- Execute a single action and return new state if valid -/
def executeAction (state : TodoState) (action : Action) : Option TodoState :=
  todoActionSystem.transition state action

/-! ## Trace Recording from Command Descriptions -/

/-- Simple command representation for recording traces -/
inductive TraceCommand where
  | add (text : String)
  | toggle (id : Nat)
  | delete (id : Nat)
  | filter (f : Filter)
  | toggleAll
  | clear
  deriving Repr

/-- Convert command to action (with text preprocessing) -/
def commandToAction (state : TodoState) (cmd : TraceCommand) : Option Action :=
  match cmd with
  | .add _ => some .addTodo
  | .toggle id => if state.items.any (·.id = id) then some (.toggleTodo id) else none
  | .delete id => if state.items.any (·.id = id) then some (.deleteTodo id) else none
  | .filter f => if state.totalItems > 0 then some (.setFilter f) else none
  | .toggleAll => if state.totalItems > 0 then some .toggleAll else none
  | .clear => some .clearCompleted

/-- Execute a command and return new state -/
def executeCommand (state : TodoState) (cmd : TraceCommand) : Option TodoState :=
  match cmd with
  | .add text =>
      let s' := TodoState.setPendingText state text
      some (TodoState.addItem s' text)
  | .toggle id => todoActionSystem.transition state (.toggleTodo id)
  | .delete id => todoActionSystem.transition state (.deleteTodo id)
  | .filter f => todoActionSystem.transition state (.setFilter f)
  | .toggleAll => todoActionSystem.transition state .toggleAll
  | .clear => todoActionSystem.transition state .clearCompleted

/-- Execute commands and record the trace -/
def recordTrace (commands : List TraceCommand) : ExecutionTrace :=
  let rec go (state : TodoState) (cmds : List TraceCommand) (states : List TodoState)
      (actions : List Action) : ExecutionTrace :=
    match cmds with
    | [] => { states := states.reverse, actions := actions.reverse }
    | cmd :: rest =>
      match executeCommand state cmd, commandToAction state cmd with
      | some s', some action => go s' rest (s' :: states) (action :: actions)
      | _, _ => go state rest states actions
  go TodoState.initial commands [TodoState.initial] []

/-! ## Verification Results -/

/-- Result of trace verification -/
structure VerificationResult where
  traceLength : Nat
  allStatesValid : Bool
  firstViolation : Option Nat  -- Index of first state that violates invariant
  deriving Repr

/-- Perform detailed verification of a trace -/
def verifyTraceDetailed (trace : ExecutionTrace) : VerificationResult :=
  let rec findViolation (states : List TodoState) (idx : Nat) : Option Nat :=
    match states with
    | [] => none
    | s :: rest =>
      if checkInvariant s then
        findViolation rest (idx + 1)
      else
        some idx
  {
    traceLength := trace.states.length
    allStatesValid := verifyTrace trace
    firstViolation := findViolation trace.states 0
  }

/-! ## Example Traces -/

/-- Example trace for testing -/
def exampleTrace : List TraceCommand := [
  .add "Buy milk",
  .add "Walk the dog",
  .add "Learn Lean 4",
  .toggle 0,
  .filter .active
]

/-- Verify the example trace -/
def verifyExample : VerificationResult :=
  let trace := recordTrace exampleTrace
  verifyTraceDetailed trace

end TodoMVC.Verification
