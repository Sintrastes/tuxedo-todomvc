/-
  TodoMVC Application Implementation

  This module implements TodoMVC as a coalgebra over an action system.
  The application state evolves according to user actions, and we can
  prove that all valid executions satisfy the LTL specification.
-/

import TuxedoMVC.LTL
import TuxedoMVC.Coalgebra
import TuxedoMVC.TodoMVC.Spec

namespace TodoMVC.App

open LTL
open Coalgebra
open TodoMVC.Spec

/-! ## User Actions -/

/-- All possible user actions in TodoMVC -/
inductive Action where
  | enterText (text : String)
  | addTodo
  | setFilter (filter : Filter)
  | toggleTodo (id : Nat)
  | deleteTodo (id : Nat)
  | toggleAll
  | clearCompleted
  deriving DecidableEq, Repr

instance : ToString Action where
  toString
    | .enterText t => s!"enterText({t})"
    | .addTodo => "addTodo"
    | .setFilter f => s!"setFilter({f})"
    | .toggleTodo id => s!"toggleTodo({id})"
    | .deleteTodo id => s!"deleteTodo({id})"
    | .toggleAll => "toggleAll"
    | .clearCompleted => "clearCompleted"

/-! ## JSON Serialization -/

/-- Escape a string for JSON -/
def escapeJsonString (s : String) : String :=
  s.replace "\\" "\\\\"
   |>.replace "\"" "\\\""
   |>.replace "\n" "\\n"
   |>.replace "\r" "\\r"
   |>.replace "\t" "\\t"

/-- Convert Filter to JSON string -/
def filterToJson (f : Filter) : String :=
  match f with
  | .all => "\"all\""
  | .active => "\"active\""
  | .completed => "\"completed\""

/-- Parse Filter from string -/
def filterFromString (s : String) : Option Filter :=
  match s.trim with
  | "all" => some .all
  | "active" => some .active
  | "completed" => some .completed
  | _ => none

/-- Convert Action to JSON string -/
def Action.toJson : Action → String
  | .enterText text => s!"\{\"type\":\"enterText\",\"text\":\"{escapeJsonString text}\"}"
  | .addTodo => "{\"type\":\"addTodo\"}"
  | .setFilter f => s!"\{\"type\":\"setFilter\",\"filter\":{filterToJson f}}"
  | .toggleTodo id => s!"\{\"type\":\"toggleTodo\",\"id\":{id}}"
  | .deleteTodo id => s!"\{\"type\":\"deleteTodo\",\"id\":{id}}"
  | .toggleAll => "{\"type\":\"toggleAll\"}"
  | .clearCompleted => "{\"type\":\"clearCompleted\"}"

/-- Find substring position in a string -/
private partial def findSubstring (str : String) (sub : String) (startPos : Nat := 0) : Option Nat :=
  let rec search (pos : Nat) : Option Nat :=
    if pos + sub.length > str.length then none
    else if (str.drop pos).take sub.length == sub then some pos
    else search (pos + 1)
  search startPos

/-- Simple JSON parser helper: extract value for a key -/
private def extractJsonValue (json : String) (key : String) : Option String := do
  let pattern := s!"\"{key}\":"
  let startIdx ← findSubstring json pattern
  let valueStart := startIdx + pattern.length
  if valueStart >= json.length then none
  else
    let c := (json.drop valueStart).front
    if c == '"' then
      -- String value
      let strStart := valueStart + 1
      let strEndOpt := findSubstring json "\"" strStart
      match strEndOpt with
      | some strEnd =>
          if strEnd > strStart then
            some ((json.drop strStart).take (strEnd - strStart))
          else none
      | none => none
    else if c.isDigit then
      -- Number value
      let numEnd := (json.drop valueStart).takeWhile (·.isDigit) |>.length
      some (json.extract ⟨valueStart⟩ ⟨valueStart + numEnd⟩)
    else none

/-- Parse Action from JSON string -/
def Action.fromJson (json : String) : Option Action := do
  let actionType ← extractJsonValue json "type"
  match actionType with
  | "enterText" =>
      let text ← extractJsonValue json "text"
      some (.enterText text)
  | "addTodo" => some .addTodo
  | "setFilter" =>
      let filterStr ← extractJsonValue json "filter"
      let filter ← filterFromString filterStr
      some (.setFilter filter)
  | "toggleTodo" =>
      let idStr ← extractJsonValue json "id"
      let id ← idStr.toNat?
      some (.toggleTodo id)
  | "deleteTodo" =>
      let idStr ← extractJsonValue json "id"
      let id ← idStr.toNat?
      some (.deleteTodo id)
  | "toggleAll" => some .toggleAll
  | "clearCompleted" => some .clearCompleted
  | _ => none

/-! ## State Manipulation Functions -/

namespace TodoState

/-- Create an empty initial state -/
def empty : TodoState := {
  items := []
  selectedFilter := none
  pendingText := ""
  nextId := 0
}

/-- Create an initial state with the All filter selected -/
def initial : TodoState := {
  items := []
  selectedFilter := some .all
  pendingText := ""
  nextId := 0
}

/-- Set the pending text -/
def setPendingText (s : TodoState) (text : String) : TodoState :=
  { s with pendingText := text }

/-- Add a new todo item -/
def addItem (s : TodoState) (text : String) : TodoState :=
  if text.isEmpty then s
  else
    let newItem : TodoItem := {
      id := s.nextId
      text := text.trim
      completed := false
    }
    { s with
      items := s.items ++ [newItem]
      pendingText := ""
      nextId := s.nextId + 1
      selectedFilter := if s.items.isEmpty then some .all else s.selectedFilter
    }

/-- Set the current filter -/
def setFilter (s : TodoState) (f : Filter) : TodoState :=
  if s.items.isEmpty then s
  else { s with selectedFilter := some f }

/-- Toggle completion status of an item by id -/
def toggleItem (s : TodoState) (id : Nat) : TodoState :=
  let items' := s.items.map fun item =>
    if item.id = id then { item with completed := !item.completed }
    else item
  { s with items := items' }

/-- Delete an item by id -/
def deleteItem (s : TodoState) (id : Nat) : TodoState :=
  let items' := s.items.filter (·.id ≠ id)
  { s with
    items := items'
    selectedFilter := if items'.isEmpty then none else s.selectedFilter
  }

/-- Toggle all items: if any unchecked, check all; otherwise uncheck all -/
def toggleAllItems (s : TodoState) : TodoState :=
  if s.items.isEmpty then s
  else
    let anyUnchecked := s.items.any (fun i => !i.completed)
    let items' := s.items.map fun item =>
      { item with completed := anyUnchecked }
    { s with items := items' }

/-- Clear all completed items -/
def clearCompletedItems (s : TodoState) : TodoState :=
  let items' := s.items.filter (fun i => !i.completed)
  { s with
    items := items'
    selectedFilter := if items'.isEmpty then none else s.selectedFilter
  }

/-- Find an item by id -/
def findItem (s : TodoState) (id : Nat) : Option TodoItem :=
  s.items.find? (·.id = id)

/-- Check if an item exists -/
def hasItem (s : TodoState) (id : Nat) : Bool :=
  s.items.any (·.id = id)

end TodoState

/-! ## Action System Definition -/

/-- The TodoMVC action system defines state transitions -/
def todoActionSystem : ActionSystem Action TodoState where
  transition := fun s action =>
    match action with
    | .enterText text =>
        some (TodoState.setPendingText s text)

    | .addTodo =>
        if s.pendingText.isEmpty then none
        else some (TodoState.addItem s s.pendingText)

    | .setFilter f =>
        if s.items.isEmpty then none
        else some (TodoState.setFilter s f)

    | .toggleTodo id =>
        if TodoState.hasItem s id then some (TodoState.toggleItem s id)
        else none

    | .deleteTodo id =>
        if TodoState.hasItem s id then some (TodoState.deleteItem s id)
        else none

    | .toggleAll =>
        if s.items.isEmpty then none
        else some (TodoState.toggleAllItems s)

    | .clearCompleted =>
        some (TodoState.clearCompletedItems s)

/-! ## Coalgebra Structure -/

/-- Convert the action system to a coalgebra -/
def todoCoalgebra : Coalg (fun S => Action → Option S) TodoState :=
  todoActionSystem.toCoalg

/-- The step function of the coalgebra -/
def step (s : TodoState) (a : Action) : Option TodoState :=
  todoActionSystem.transition s a

/-! ## Preconditions for Actions -/

/-- Precondition: when is an action enabled? -/
def actionEnabled (s : TodoState) : Action → Bool
  | .enterText _ => true
  | .addTodo => !s.pendingText.isEmpty
  | .setFilter _ => !s.items.isEmpty
  | .toggleTodo id => TodoState.hasItem s id
  | .deleteTodo id => TodoState.hasItem s id
  | .toggleAll => !s.items.isEmpty
  | .clearCompleted => true

end TodoMVC.App
