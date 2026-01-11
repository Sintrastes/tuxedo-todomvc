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

import TuxedoMVC.LTL
import TuxedoMVC.Coalgebra
import TuxedoMVC.TodoMVC.Types

namespace TodoMVC.Spec

open LTL
open LTL.Formula
open Coalgebra
open TodoMVC.Types

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
