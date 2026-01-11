/-
  TodoMVC CLI Driver

  This module provides a command-line interface for interacting with
  the TodoMVC application.
-/

import LtlFormalVerification.LTL
import LtlFormalVerification.Coalgebra
import LtlFormalVerification.TodoMVC.Spec
import LtlFormalVerification.TodoMVC.App

namespace TodoMVC.Driver

open TodoMVC.Spec
open TodoMVC.App

/-! ## REPL State -/

/-- The REPL maintains both the todo state and command history -/
structure ReplState where
  todoState : TodoState
  history : List TodoState
  stepByStep : Bool  -- Interactive step-by-step mode
  deriving Repr

/-- Initial REPL state -/
def ReplState.initial : ReplState := {
  todoState := TodoState.initial
  history := []
  stepByStep := false
}

/-! ## Command Parsing -/

/-- Parsed command from user input -/
inductive Command where
  | add (text : String)
  | toggle (id : Nat)
  | delete (id : Nat)
  | filter (f : Filter)
  | toggleAll
  | clear
  | undo
  | list
  | help
  | quit
  | step (enable : Bool)
  | invalid (msg : String)
  deriving Repr

/-- Parse a user command -/
def parseCommand (input : String) : Command :=
  let parts := input.trim.splitOn " "
  match parts with
  | ["add"] => .invalid "Usage: add <text>"
  | "add" :: rest => .add (String.intercalate " " rest)
  | ["toggle", idStr] =>
      match idStr.toNat? with
      | some id => .toggle id
      | none => .invalid s!"Invalid id: {idStr}"
  | ["delete", idStr] | ["del", idStr] | ["rm", idStr] =>
      match idStr.toNat? with
      | some id => .delete id
      | none => .invalid s!"Invalid id: {idStr}"
  | ["filter", "all"] | ["all"] => .filter .all
  | ["filter", "active"] | ["active"] => .filter .active
  | ["filter", "completed"] | ["completed"] | ["done"] => .filter .completed
  | ["toggleall"] | ["toggle-all"] => .toggleAll
  | ["clear"] | ["clear-completed"] => .clear
  | ["undo"] | ["u"] => .undo
  | ["list"] | ["ls"] | ["show"] | [""] => .list
  | ["help"] | ["h"] | ["?"] => .help
  | ["quit"] | ["exit"] | ["q"] => .quit
  | ["step", "on"] | ["step", "true"] => .step true
  | ["step", "off"] | ["step", "false"] => .step false
  | ["step"] => .step true
  | _ => .invalid s!"Unknown command: {input.trim}. Type 'help' for commands."

/-! ## Command Execution -/

/-- Result of executing a command -/
inductive ExecResult where
  | continue (state : ReplState) (msg : String)
  | quit (msg : String)

/-- Help text for available commands -/
def helpText : String :=
"═══ TodoMVC Commands ═══
  add <text>      Add a new todo item
  toggle <id>     Toggle completion status of item
  delete <id>     Delete an item (aliases: del, rm)
  all             Show all items
  active          Show active (uncompleted) items
  completed       Show completed items (alias: done)
  toggleall       Toggle all items
  clear           Clear all completed items
  undo            Undo last action
  list            Show current state (aliases: ls, show)
  step [on|off]   Toggle step-by-step mode (shows transitions)
  help            Show this help (aliases: h, ?)
  quit            Exit the program (aliases: exit, q)
═══════════════════════════"

/-- Display detailed state comparison for step-by-step mode -/
def stepByStepMessage (before : TodoState) (after : TodoState) (action : Action) (summary : String) : String :=
  let separator := "─────────────────────────────"
  let actionStr := s!"⚡ Action: {action}"

  let beforeInfo := s!"  Before: {before.totalItems} items, {before.numUnchecked} active, filter={before.selectedFilter}"
  let afterInfo := s!"  After:  {after.totalItems} items, {after.numUnchecked} active, filter={after.selectedFilter}"

  let changes :=
    let itemChange := after.totalItems - before.totalItems
    let activeChange := after.numUnchecked - before.numUnchecked
    let itemStr := if itemChange > 0 then s!"(+{itemChange} items)"
                   else if itemChange < 0 then s!"({itemChange} items)"
                   else ""
    let activeStr := if activeChange > 0 then s!"(+{activeChange} active)"
                     else if activeChange < 0 then s!"({activeChange} active)"
                     else ""
    let filterStr := if before.selectedFilter != after.selectedFilter then
                       s!"(filter changed: {before.selectedFilter} → {after.selectedFilter})"
                     else ""
    [itemStr, activeStr, filterStr].filter (·.isEmpty == false) |> String.intercalate " "

  let changesLine := if changes.isEmpty then "" else s!"  Changes: {changes}\n"

  s!"\n{separator}\n{actionStr}\n{beforeInfo}\n{afterInfo}\n{changesLine}{separator}\n{summary}"

/-- Execute a command and return the new state -/
def executeCommand (state : ReplState) (cmd : Command) : ExecResult :=
  match cmd with
  | .add text =>
      let s := state.todoState
      let s' := TodoState.addItem (TodoState.setPendingText s text) text
      let newState := { state with
        todoState := s'
        history := state.todoState :: state.history
      }
      if state.stepByStep then
        .continue newState (stepByStepMessage s s' (.addTodo) s!"Added: {text}")
      else
        .continue newState s!"Added: {text}"

  | .toggle id =>
      match todoActionSystem.transition state.todoState (.toggleTodo id) with
      | some s' =>
          let newState := { state with
            todoState := s'
            history := state.todoState :: state.history
          }
          if state.stepByStep then
            .continue newState (stepByStepMessage state.todoState s' (.toggleTodo id) s!"Toggled item {id}")
          else
            .continue newState s!"Toggled item {id}"
      | none =>
          .continue state s!"Item {id} not found"

  | .delete id =>
      match todoActionSystem.transition state.todoState (.deleteTodo id) with
      | some s' =>
          let newState := { state with
            todoState := s'
            history := state.todoState :: state.history
          }
          if state.stepByStep then
            .continue newState (stepByStepMessage state.todoState s' (.deleteTodo id) s!"Deleted item {id}")
          else
            .continue newState s!"Deleted item {id}"
      | none =>
          .continue state s!"Item {id} not found"

  | .filter f =>
      match todoActionSystem.transition state.todoState (.setFilter f) with
      | some s' =>
          let newState := { state with
            todoState := s'
            history := state.todoState :: state.history
          }
          if state.stepByStep then
            .continue newState (stepByStepMessage state.todoState s' (.setFilter f) s!"Filter set to {f}")
          else
            .continue newState s!"Filter set to {f}"
      | none =>
          .continue state "Cannot change filter (no items)"

  | .toggleAll =>
      match todoActionSystem.transition state.todoState .toggleAll with
      | some s' =>
          let newState := { state with
            todoState := s'
            history := state.todoState :: state.history
          }
          if state.stepByStep then
            .continue newState (stepByStepMessage state.todoState s' .toggleAll "Toggled all items")
          else
            .continue newState "Toggled all items"
      | none =>
          .continue state "No items to toggle"

  | .clear =>
      match todoActionSystem.transition state.todoState .clearCompleted with
      | some s' =>
          let newState := { state with
            todoState := s'
            history := state.todoState :: state.history
          }
          if state.stepByStep then
            .continue newState (stepByStepMessage state.todoState s' .clearCompleted "Cleared completed items")
          else
            .continue newState "Cleared completed items"
      | none =>
          .continue state "Error clearing completed items"

  | .undo =>
      match state.history with
      | [] => .continue state "Nothing to undo"
      | prev :: rest =>
          let newState := { state with
            todoState := prev
            history := rest
          }
          .continue newState "Undone"

  | .list =>
      .continue state ""

  | .help =>
      .continue state helpText

  | .quit =>
      .quit "Goodbye!"

  | .step enable =>
      let newState := { state with stepByStep := enable }
      let msg := if enable then
        "✓ Step-by-step mode enabled - detailed transitions will be shown"
      else
        "Step-by-step mode disabled"
      .continue newState msg

  | .invalid msg =>
      .continue state msg

/-! ## Display Functions -/

/-- Render the current state with item IDs visible -/
def renderWithIds (s : TodoState) : String :=
  let header := "\n╔═══════════════════════════╗\n║         TODOS             ║\n╠═══════════════════════════╣\n"
  let items := if s.visibleItems.isEmpty then
      "║  (no items)               ║\n"
    else
      String.join (s.visibleItems.map (fun item =>
        let mark := if item.completed then "✓" else " "
        let text := item.text.take 18
        let padding := String.ofList (List.replicate (18 - min 18 text.length) ' ')
        s!"║ {item.id}: [{mark}] {text}{padding}║\n"
      ))
  let divider := "╠═══════════════════════════╣\n"
  let footer := match s.selectedFilter with
    | none => "╚═══════════════════════════╝\n"
    | some f =>
      let filterStr := match f with
        | .all => "[All] Active Completed"
        | .active => "All [Active] Completed"
        | .completed => "All Active [Completed]"
      let count := s!"{s.numUnchecked} items left"
      s!"{divider}║ {count}{"".pushn ' ' (25 - count.length)}║\n║ {filterStr} ║\n╚═══════════════════════════╝\n"
  header ++ items ++ footer

/-- Display prompt -/
def prompt : String := "todo> "

/-! ## Main REPL -/

/-- Run one iteration of the REPL -/
def replStep (state : ReplState) (input : String) : ExecResult :=
  let cmd := parseCommand input
  executeCommand state cmd

/-- The main REPL loop -/
partial def repl (state : ReplState) : IO Unit := do
  IO.print (renderWithIds state.todoState)
  IO.print prompt
  let stdout ← IO.getStdout
  stdout.flush
  let stdin ← IO.getStdin
  let input ← stdin.getLine
  let input := input.trim
  match replStep state input with
  | .continue newState msg =>
      if !msg.isEmpty then
        IO.println msg
      repl newState
  | .quit msg =>
      IO.println msg

/-- Entry point for the CLI driver -/
def main : IO Unit := do
  IO.println "╔═══════════════════════════════════════╗"
  IO.println "║   TodoMVC - Formally Verified Edition  ║"
  IO.println "║   Type 'help' for available commands   ║"
  IO.println "║   Type 'step on' for detailed mode     ║"
  IO.println "╚═══════════════════════════════════════╝"
  repl ReplState.initial

/-- Entry point for interactive step-by-step mode -/
def mainStepByStep : IO Unit := do
  IO.println "╔═══════════════════════════════════════╗"
  IO.println "║   TodoMVC - Formally Verified Edition  ║"
  IO.println "║        STEP-BY-STEP MODE ACTIVE        ║"
  IO.println "║   All transitions will show details    ║"
  IO.println "╚═══════════════════════════════════════╝"
  let initialState := { ReplState.initial with stepByStep := true }
  repl initialState



end TodoMVC.Driver
