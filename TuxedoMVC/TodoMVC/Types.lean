/-
  TodoMVC Data Types

  This module contains the core data structures for TodoMVC:
  - Filter: The filter modes (All, Active, Completed)
  - TodoItem: Individual todo items
  - TodoState: Complete application state

  These types are used by both the specification (Spec) and implementation (App).
-/

import TuxedoMVC.LTL
import TuxedoMVC.Coalgebra

namespace TodoMVC.Types

/-! ## Filter Type -/

/-- The filter modes for viewing todos -/
inductive Filter where
  | all : Filter
  | active : Filter
  | completed : Filter
  deriving DecidableEq, Repr, Inhabited

instance : ToString Filter where
  toString
    | .all => "All"
    | .active => "Active"
    | .completed => "Completed"

/-! ## Todo Item -/

/-- A single todo item -/
structure TodoItem where
  /-- Unique identifier -/
  id : Nat
  /-- The text content of the todo -/
  text : String
  /-- Whether the todo is completed -/
  completed : Bool
  deriving DecidableEq, Repr

instance : ToString TodoItem where
  toString item := s!"[{if item.completed then "x" else " "}] {item.text}"

/-! ## Application State -/

/-- The complete state of a TodoMVC application -/
structure TodoState where
  /-- All todo items -/
  items : List TodoItem
  /-- Currently selected filter (None means no todos yet) -/
  selectedFilter : Option Filter
  /-- Text currently in the new todo input field -/
  pendingText : String
  /-- Next available ID for new todos -/
  nextId : Nat
  deriving DecidableEq, Repr

namespace TodoState

/-- Get visible items based on current filter -/
def visibleItems (s : TodoState) : List TodoItem :=
  match s.selectedFilter with
  | none => []
  | some .all => s.items
  | some .active => s.items.filter (fun i => !i.completed)
  | some .completed => s.items.filter (fun i => i.completed)

/-- Number of visible items -/
def numItems (s : TodoState) : Nat := s.visibleItems.length

/-- Number of unchecked (active) items -/
def numUnchecked (s : TodoState) : Nat :=
  (s.items.filter (fun i => !i.completed)).length

/-- Number of checked (completed) items -/
def numChecked (s : TodoState) : Nat :=
  (s.items.filter (fun i => i.completed)).length

/-- Number of items left (shown in footer) -/
def numItemsLeft (s : TodoState) : Option Nat :=
  if s.items.isEmpty then none else some s.numUnchecked

/-- Get all visible item texts -/
def itemTexts (s : TodoState) : List String :=
  s.visibleItems.map (·.text)

/-- Get the last visible item's text -/
def lastItemText (s : TodoState) : Option String :=
  s.visibleItems.getLast?.map (·.text)

/-- Total number of items (regardless of filter) -/
def totalItems (s : TodoState) : Nat := s.items.length

/-- Empty state with no filter selected -/
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

end TodoState

/-! ## JSON Serialization -/

/-- Escape a string for JSON -/
def escapeJsonString (s : String) : String :=
  s.replace "\\" "\\\\"
   |>.replace "\"" "\\\""
   |>.replace "\n" "\\n"
   |>.replace "\r" "\\r"
   |>.replace "\t" "\\t"

/-- Convert Filter to JSON string -/
def Filter.toJson : Filter → String
  | .all => "\"all\""
  | .active => "\"active\""
  | .completed => "\"completed\""

/-- Parse Filter from JSON string -/
def Filter.fromJson (s : String) : Option Filter :=
  match s.trim.replace "\"" "" with
  | "all" => some .all
  | "active" => some .active
  | "completed" => some .completed
  | _ => none

/-- Convert TodoItem to JSON string -/
def TodoItem.toJson (item : TodoItem) : String :=
  s!"\{\"id\":{item.id},\"text\":\"{escapeJsonString item.text}\",\"completed\":{item.completed}}"

/-- Convert list of TodoItems to JSON array -/
def todoItemsToJson (items : List TodoItem) : String :=
  "[" ++ String.intercalate "," (items.map TodoItem.toJson) ++ "]"

/-- Convert Option Filter to JSON -/
def optionFilterToJson : Option Filter → String
  | none => "null"
  | some f => Filter.toJson f

/-- Convert TodoState to JSON string -/
def TodoState.toJson (s : TodoState) : String :=
  let itemsJson := todoItemsToJson s.items
  let filterJson := optionFilterToJson s.selectedFilter
  let pendingTextJson := s!"\"{escapeJsonString s.pendingText}\""
  s!"\{\"items\":{itemsJson},\"selectedFilter\":{filterJson},\"pendingText\":{pendingTextJson},\"nextId\":{s.nextId}}"

/-- Find substring position in a string -/
private partial def findSubstring (str : String) (sub : String) : Option Nat :=
  let rec search (pos : Nat) : Option Nat :=
    if pos + sub.length > str.length then none
    else if (str.drop pos).take sub.length == sub then some pos
    else search (pos + 1)
  search 0

/-- Simple JSON parser helper: extract value for a key -/
private def extractJsonValue (json : String) (key : String) : Option String := do
  let pattern := s!"\"{key}\":"
  let startIdx ← findSubstring json pattern
  let valueStart := startIdx + pattern.length
  if valueStart >= json.length then none
  else
    let remaining := json.drop valueStart
    -- Skip whitespace
    let remaining := remaining.dropWhile (·.isWhitespace)
    if remaining.isEmpty then none
    else
      let c := remaining.front
      if c == '"' then
        -- String value
        let strContent := remaining.drop 1
        let strEndOpt := findSubstring strContent "\""
        match strEndOpt with
        | some strEnd => some (strContent.take strEnd)
        | none => none
      else if c.isDigit then
        -- Number value
        let numStr := remaining.takeWhile (fun ch => ch.isDigit)
        some numStr
      else if remaining.startsWith "null" then
        some "null"
      else if remaining.startsWith "true" then
        some "true"
      else if remaining.startsWith "false" then
        some "false"
      else none

/-- Parse TodoState from JSON string -/
def TodoState.fromJson (json : String) : Option TodoState := do
  let pendingText ← extractJsonValue json "pendingText"
  let nextIdStr ← extractJsonValue json "nextId"
  let nextId ← nextIdStr.toNat?

  let filterStr ← extractJsonValue json "selectedFilter"
  let selectedFilter :=
    if filterStr == "null" then none
    else Filter.fromJson filterStr

  -- For simplicity, we'll reconstruct items as empty list initially
  -- In practice, the web app will maintain items through transitions
  some {
    items := []
    selectedFilter := selectedFilter
    pendingText := pendingText
    nextId := nextId
  }

end TodoMVC.Types
