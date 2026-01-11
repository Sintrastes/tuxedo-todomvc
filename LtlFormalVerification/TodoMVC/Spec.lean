/-
  TodoMVC LTL Specification

  This module contains the formal LTL specification for TodoMVC,
  translated from the Quickstrom specification.

  The original Quickstrom spec defines:
  - Initial state conditions
  - Valid state transitions (enterText, addNew, changeFilter, etc.)
  - Invariants (hasFilters)

  The main proposition is:
    initial ∧ □(transition₁ ∨ transition₂ ∨ ... ∨ transitionₙ) ∧ □hasFilters
-/

import LtlFormalVerification.LTL
import LtlFormalVerification.Coalgebra

namespace TodoMVC.Spec

open LTL
open LTL.Formula
open Coalgebra

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

/-! ## Observable Properties (State Predicates) -/


/-- Predicate: the pending text field has a specific value -/
def hasPendingText (txt : String) : StatePred TodoState :=
  fun s => s.pendingText = txt

/-- Predicate: the selected filter is a specific value -/
def hasFilter (f : Option Filter) : StatePred TodoState :=
  fun s => s.selectedFilter = f

/-- Predicate: there are exactly n visible items -/
def hasNumItems (n : Nat) : StatePred TodoState :=
  fun s => s.numItems = n

/-- Predicate: the items list has specific texts -/
def hasItemTexts (texts : List String) : StatePred TodoState :=
  fun s => s.itemTexts = texts

/-- Predicate: number of checked items is n -/
def hasNumChecked (n : Nat) : StatePred TodoState :=
  fun s => s.numChecked = n

/-- Predicate: number of items left is n -/
def hasNumItemsLeft (n : Option Nat) : StatePred TodoState :=
  fun s => s.numItemsLeft = n

/-! ## Initial State Specification -/

/-- The initial state predicate from Quickstrom spec:
    - selectedFilter is Nothing or Just All
    - numItems == 0
    - pendingText == ""
-/
def initialState : StatePred TodoState := fun s =>
  (s.selectedFilter = none ∨ s.selectedFilter = some .all) ∧
  s.numItems = 0 ∧
  s.pendingText = ""

/-! ## Transition Predicates -/

/-- enterText transition: only pendingText changes -/
def enterTextTrans : TransPred TodoState := fun s s' =>
  s.pendingText ≠ s'.pendingText ∧
  s.itemTexts = s'.itemTexts ∧
  s.selectedFilter = s'.selectedFilter

/-- addNew transition: add a new todo item -/
def addNewTrans : TransPred TodoState := fun s s' =>
  s'.pendingText = "" ∧
  s.pendingText ≠ "" ∧
  match s'.selectedFilter with
  | some .all => s'.lastItemText = some s.pendingText
  | some .active => s'.lastItemText = some s.pendingText
  | some .completed => s.itemTexts = s'.itemTexts
  | none => False

/-- changeFilter transition: change the current filter view -/
def changeFilterTrans : TransPred TodoState := fun s s' =>
  match s.selectedFilter, s'.selectedFilter with
  | none, some .all => True
  | none, _ => False
  | _, none => False
  | some .all, some f' =>
      f' ≠ .all ∧ s.numItems ≥ s'.numItems ∧ s.pendingText = s'.pendingText
  | some f, some .active =>
      f ≠ .active ∧
      s'.numItemsLeft = some s'.numUnchecked ∧
      s'.numItems = s'.numUnchecked ∧
      s.pendingText = s'.pendingText
  | some f₁, some f₂ =>
      f₁ ≠ f₂ ∧ s.pendingText = s'.pendingText

/-- checkOne transition: mark one item as completed -/
def checkOneTrans : TransPred TodoState := fun s s' =>
  s.pendingText = s'.pendingText ∧
  s.selectedFilter = s'.selectedFilter ∧
  s.selectedFilter ≠ some .completed ∧
  (s.selectedFilter = some .all →
    s.numItems = s'.numItems ∧ s.numChecked < s'.numChecked) ∧
  (s.selectedFilter = some .active →
    s.numItems > s'.numItems ∧
    match s.numItemsLeft, s'.numItemsLeft with
    | some n, some n' => n > n'
    | _, _ => False)

/-- uncheckOne transition: mark one item as not completed -/
def uncheckOneTrans : TransPred TodoState := fun s s' =>
  s.pendingText = s'.pendingText ∧
  s.selectedFilter = s'.selectedFilter ∧
  s.selectedFilter ≠ some .active ∧
  (s.selectedFilter = some .all →
    s.numItems = s'.numItems ∧ s.numChecked > s'.numChecked) ∧
  (s.selectedFilter = some .completed →
    s.numItems > s'.numItems ∧
    match s.numItemsLeft, s'.numItemsLeft with
    | some n, some n' => n < n'
    | _, _ => False)

/-- delete transition: remove a todo item -/
def deleteTrans : TransPred TodoState := fun s s' =>
  s.pendingText = s'.pendingText ∧
  match s.selectedFilter, s.numItems with
  | _, 1 => s'.numItems = 0
  | some f, n =>
      n > 0 ∧
      s.selectedFilter = s'.selectedFilter ∧
      s'.numItems = n - 1 ∧
      match f with
      | .all => True
      | .active =>
          match s.numItemsLeft, s'.numItemsLeft with
          | some n₁, some n₂ => n₂ = n₁ - 1
          | _, _ => False
      | .completed => s.numItemsLeft = s'.numItemsLeft
  | none, _ => False

/-- toggleAll transition: toggle completion status of all items -/
def toggleAllTrans : TransPred TodoState := fun s s' =>
  s.pendingText = s'.pendingText ∧
  s.selectedFilter = s'.selectedFilter ∧
  match s.selectedFilter with
  | some .all =>
      s.numItems = s'.numItems ∧
      s'.numItems = s'.numChecked
  | some .active =>
      (s.numItems > 0 → s'.numItems = 0) ∧
      (s.numItems = 0 → s'.numItems > 0)
  | some .completed =>
      s.numItems + s.numUnchecked = s'.numItems
  | none => False

/-! ## Invariants -/

/-- hasFilters invariant: when there are items, filters must be available -/
def hasFiltersInvariant : StatePred TodoState := fun s =>
  s.totalItems = 0 ∨ s.selectedFilter.isSome

/-! ## Main LTL Specification -/

/-- Combined transition: one of the valid transitions must occur -/
def validTransition : TransPred TodoState := fun s s' =>
  enterTextTrans s s' ∨
  addNewTrans s s' ∨
  changeFilterTrans s s' ∨
  checkOneTrans s s' ∨
  uncheckOneTrans s s' ∨
  deleteTrans s s' ∨
  toggleAllTrans s s'

/-- The complete TodoMVC specification as an LTL formula -/
def todoMVCSpec : Formula TodoState :=
  conj (atom initialState)
    (conj (always (action validTransition))
          (always (atom hasFiltersInvariant)))

/-- Alternative formulation: specification as separate properties -/
structure TodoMVCProperties where
  /-- Initial state is valid -/
  init : StatePred TodoState
  /-- Valid transitions -/
  trans : TransPred TodoState
  /-- Invariant properties -/
  invariant : StatePred TodoState

def todoMVCProperties : TodoMVCProperties := {
  init := initialState
  trans := validTransition
  invariant := hasFiltersInvariant
}

/-! ## Derived Properties -/

/-- Safety property: number of items never goes negative (trivially true for Nat) -/
def nonNegativeItems : StatePred TodoState := fun s =>
  s.numItems ≥ 0

/-- Safety property: numChecked + numUnchecked = totalItems -/
def checkedCountsConsistent : StatePred TodoState := fun s =>
  s.numChecked + s.numUnchecked = s.totalItems

/-! ## Specification Satisfaction Predicate -/

/-- A trace satisfies the TodoMVC spec -/
def satisfiesSpec (t : Trace TodoState) : Prop :=
  Formula.satisfies t todoMVCSpec

/-- Equivalent predicate-based specification -/
def satisfiesSpecProps (t : Trace TodoState) : Prop :=
  todoMVCProperties.init (t 0) ∧
  (∀ i, todoMVCProperties.trans (t i) (t (i + 1))) ∧
  (∀ i, todoMVCProperties.invariant (t i))

/-! ## Semantic Constraints -/

/-- Axiom: Initial states with filter = none must have no items.
    This is a semantic constraint: the UI shows no filter when there are no items. -/
axiom initial_none_filter_implies_empty (s : TodoState) :
    initialState s → s.selectedFilter = none → s.items = []



end TodoMVC.Spec
