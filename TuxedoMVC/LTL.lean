/-
  LTL (Linear Temporal Logic) Specification Framework

  This module provides a framework for expressing and reasoning
  about Linear Temporal Logic specifications in Lean 4.
-/

namespace LTL

/-- A Trace is an infinite sequence of states -/
def Trace (σ : Type u) := Nat → σ

/-- Suffix of a trace starting at position i -/
def Trace.suffix {σ : Type u} (t : Trace σ) (i : Nat) : Trace σ :=
  fun n => t (i + n)

/-- The head (first element) of a trace -/
def Trace.head {σ : Type u} (t : Trace σ) : σ := t 0

/-- The tail of a trace (suffix starting at position 1) -/
def Trace.tail {σ : Type u} (t : Trace σ) : Trace σ := t.suffix 1

/-- State predicate: a property that holds at a single state -/
def StatePred (σ : Type u) := σ → Prop

/-- Transition predicate: a property relating two consecutive states -/
def TransPred (σ : Type u) := σ → σ → Prop

/-- LTL Formula datatype -/
inductive Formula (σ : Type u) where
  | atom : StatePred σ → Formula σ
  | tt : Formula σ
  | ff : Formula σ
  | neg : Formula σ → Formula σ
  | conj : Formula σ → Formula σ → Formula σ
  | disj : Formula σ → Formula σ → Formula σ
  | impl : Formula σ → Formula σ → Formula σ
  | next : Formula σ → Formula σ
  | always : Formula σ → Formula σ
  | eventually : Formula σ → Formula σ
  | untilF : Formula σ → Formula σ → Formula σ
  | action : TransPred σ → Formula σ

namespace Formula

/-- Satisfaction relation: trace t satisfies formula φ -/
def satisfies {σ : Type u} : Trace σ → Formula σ → Prop
  | t, atom p => p (t.head)
  | _, tt => True
  | _, ff => False
  | t, neg φ => ¬(satisfies t φ)
  | t, conj φ ψ => satisfies t φ ∧ satisfies t ψ
  | t, disj φ ψ => satisfies t φ ∨ satisfies t ψ
  | t, impl φ ψ => satisfies t φ → satisfies t ψ
  | t, next φ => satisfies t.tail φ
  | t, always φ => ∀ i, satisfies (t.suffix i) φ
  | t, eventually φ => ∃ i, satisfies (t.suffix i) φ
  | t, untilF φ ψ => ∃ j, satisfies (t.suffix j) ψ ∧ ∀ i, i < j → satisfies (t.suffix i) φ
  | t, action r => r (t 0) (t 1)

/-- A formula is valid if it holds on all traces -/
def valid {σ : Type u} (φ : Formula σ) : Prop :=
  ∀ t : Trace σ, satisfies t φ

/-- Semantic equivalence of formulas -/
def equiv {σ : Type u} (φ ψ : Formula σ) : Prop :=
  ∀ t : Trace σ, (satisfies t φ) ↔ (satisfies t ψ)

end Formula

open Formula

/-! ## Basic Lemmas -/

section Lemmas

variable {σ : Type u}

/-- Suffix at 0 is the original trace -/
@[simp]
theorem suffix_zero (t : Trace σ) : t.suffix 0 = t := by
  funext n
  simp only [Trace.suffix, Nat.zero_add]

/-- Composing suffixes -/
theorem suffix_suffix (t : Trace σ) (i j : Nat) :
    (t.suffix i).suffix j = t.suffix (i + j) := by
  funext n
  simp only [Trace.suffix, Nat.add_assoc]

/-- Tail is suffix at 1 -/
theorem tail_eq_suffix_one (t : Trace σ) : t.tail = t.suffix 1 := rfl

/-- Always implies current state -/
theorem always_implies_now (t : Trace σ) (φ : Formula σ) :
    satisfies t (always φ) → satisfies t φ := by
  intro h
  have h0 := h 0
  simp only [suffix_zero] at h0
  exact h0

/-- Until implies eventually -/
theorem until_implies_eventually (t : Trace σ) (φ ψ : Formula σ) :
    satisfies t (untilF φ ψ) → satisfies t (eventually ψ) := by
  intro ⟨j, hψ, _⟩
  exact ⟨j, hψ⟩

/-- Always distributes over conjunction -/
theorem always_conj (t : Trace σ) (φ ψ : Formula σ) :
    satisfies t (always (conj φ ψ)) ↔ satisfies t (conj (always φ) (always ψ)) := by
  simp only [satisfies]
  constructor
  · intro h
    constructor
    · intro i; exact (h i).1
    · intro i; exact (h i).2
  · intro ⟨hφ, hψ⟩ i
    exact ⟨hφ i, hψ i⟩

end Lemmas

/-! ## Induction Principles for LTL Proofs -/

section Induction

variable {σ : Type u}

/-- Induction principle for always: if P holds initially and is preserved, then □P holds -/
theorem always_induction (t : Trace σ) (P : StatePred σ)
    (hinit : P (t.head))
    (hstep : ∀ i, P (t i) → P (t (i + 1))) :
    satisfies t (always (atom P)) := by
  intro i
  simp only [satisfies, Trace.suffix, Trace.head, Nat.add_zero]
  induction i with
  | zero => exact hinit
  | succ n ih =>
    have step := hstep n ih
    exact step

/-- Strong induction for eventually proofs -/
theorem eventually_witness (t : Trace σ) (P : StatePred σ) (n : Nat)
    (h : P (t n)) : satisfies t (eventually (atom P)) := by
  refine ⟨n, ?_⟩
  simp only [satisfies, Trace.suffix, Trace.head, Nat.add_zero]
  exact h

end Induction

/-! ## Finite Trace Semantics (for bounded model checking) -/

/-- A finite trace is a list of states -/
abbrev FiniteTrace (σ : Type u) := List σ

namespace FiniteTrace

/-- Convert finite trace to infinite trace by repeating last element -/
def toInfinite {σ : Type u} [Inhabited σ] (ft : FiniteTrace σ) : Trace σ :=
  fun i => ft.getD i (ft.getLast?.getD default)

/-- Get all states in a finite trace -/
def states {σ : Type u} (ft : FiniteTrace σ) : List σ := ft

/-- Check if all states satisfy a predicate -/
def allSatisfy {σ : Type u} (ft : FiniteTrace σ) (p : σ → Bool) : Bool :=
  ft.all p

end FiniteTrace

end LTL
