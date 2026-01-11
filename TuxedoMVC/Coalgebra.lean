/-
  Coalgebraic Modeling Framework

  This module provides a coalgebraic approach to modeling stateful applications.
  A coalgebra is a structure (S, step : S → F S) where F is a functor representing
  the "shape" of possible transitions.
-/

import TuxedoMVC.LTL

namespace Coalgebra

open LTL

/-! ## Action-Based Transition Systems -/

/-- An action system represents a stateful application with discrete actions -/
structure ActionSystem (Action : Type u) (State : Type v) where
  /-- Given a state and action, produce the next state (if the action is applicable) -/
  transition : State → Action → Option State

/-- Predicate for whether an action is enabled in a state -/
def ActionSystem.enabled {Action : Type u} {State : Type v}
    (sys : ActionSystem Action State) (s : State) (a : Action) : Prop :=
  (sys.transition s a).isSome

/-! ## Coalgebra Definition -/

/-- A coalgebra over a functor F with carrier type S -/
structure Coalg (F : Type u → Type v) (S : Type u) where
  /-- The transition function mapping states to their possible successors -/
  step : S → F S

/-- Convert an action system to a coalgebra -/
def ActionSystem.toCoalg {Action : Type u} {State : Type v}
    (sys : ActionSystem Action State) : Coalg (fun S => Action → Option S) State :=
  ⟨fun s a => sys.transition s a⟩

/-! ## Deterministic Transition Systems -/

/-- A deterministic transition system with enumerable actions -/
structure DeterministicTS (Action : Type u) (State : Type v) where
  /-- Initial state -/
  init : State
  /-- Deterministic transition function -/
  step : State → Action → State
  /-- Precondition for action applicability -/
  pre : State → Action → Prop := fun _ _ => True

/-- Convert a deterministic TS to an action system -/
def DeterministicTS.toActionSystem {Action : Type u} {State : Type v}
    (dts : DeterministicTS Action State)
    [∀ s a, Decidable (dts.pre s a)] : ActionSystem Action State where
  transition s a := if dts.pre s a then some (dts.step s a) else none

/-! ## Execution and Traces -/

/-- An execution is an infinite sequence of states and actions -/
structure Execution (Action : Type u) (State : Type v) (sys : ActionSystem Action State) where
  /-- The sequence of states -/
  states : Nat → State
  /-- The sequence of actions -/
  actions : Nat → Action
  /-- Validity: each transition is valid -/
  valid : ∀ i, sys.transition (states i) (actions i) = some (states (i + 1))

/-- Convert an execution to an LTL trace -/
def Execution.toTrace {Action : Type u} {State : Type v} {sys : ActionSystem Action State}
    (exec : Execution Action State sys) : Trace State :=
  exec.states

/-! ## Invariants -/

/-- Inductive invariant for proving □P -/
structure Invariant {Action : Type u} {State : Type v}
    (sys : ActionSystem Action State)
    (P : StatePred State) where
  /-- P holds on initial state -/
  init_holds : ∀ s₀, P s₀ → P s₀
  /-- P is preserved by all transitions -/
  step_preserves : ∀ s a s', P s → sys.transition s a = some s' → P s'

/-- An invariant implies □P for all executions starting in a state satisfying P -/
theorem invariant_implies_always {Action : Type u} {State : Type v}
    (sys : ActionSystem Action State)
    (P : StatePred State)
    (inv : Invariant sys P)
    (exec : Execution Action State sys)
    (h_init : P (exec.states 0)) :
    Formula.satisfies exec.toTrace (Formula.always (Formula.atom P)) := by
  intro i
  simp only [Formula.satisfies, Trace.suffix, Trace.head, Execution.toTrace, Nat.add_zero]
  induction i with
  | zero => exact h_init
  | succ n ih =>
    have h_valid := exec.valid n
    exact inv.step_preserves (exec.states n) (exec.actions n) (exec.states (n + 1)) ih h_valid

/-! ## System Satisfaction -/

/-- A system satisfies a specification if all executions satisfy the LTL formula -/
def SystemSatisfies {Action : Type u} {State : Type v}
    (sys : ActionSystem Action State)
    (init : State)
    (spec : Formula State) : Prop :=
  ∀ exec : Execution Action State sys,
    exec.states 0 = init →
    Formula.satisfies exec.toTrace spec

/-! ## Observable Behavior -/

/-- An observation function extracts observable values from state -/
structure Observer (State : Type u) (Obs : Type v) where
  observe : State → Obs

/-- Two states are observationally equivalent -/
def ObsEquiv {State : Type u} {Obs : Type v} (obs : Observer State Obs) (s₁ s₂ : State) : Prop :=
  obs.observe s₁ = obs.observe s₂

/-- Observational equivalence is reflexive -/
theorem obsEquiv_refl {State : Type u} {Obs : Type v} (obs : Observer State Obs) (s : State) :
    ObsEquiv obs s s := rfl

/-- Observational equivalence is symmetric -/
theorem obsEquiv_symm {State : Type u} {Obs : Type v} (obs : Observer State Obs) (s₁ s₂ : State) :
    ObsEquiv obs s₁ s₂ → ObsEquiv obs s₂ s₁ := Eq.symm

/-- Observational equivalence is transitive -/
theorem obsEquiv_trans {State : Type u} {Obs : Type v} (obs : Observer State Obs)
    (s₁ s₂ s₃ : State) :
    ObsEquiv obs s₁ s₂ → ObsEquiv obs s₂ s₃ → ObsEquiv obs s₁ s₃ := Eq.trans

/-! ## Simulation Relations -/

/-- A simulation relation (one-directional bisimulation) -/
def Simulation {Action : Type u} {State₁ : Type v} {State₂ : Type w}
    (sys₁ : ActionSystem Action State₁)
    (sys₂ : ActionSystem Action State₂)
    (R : State₁ → State₂ → Prop) : Prop :=
  ∀ s₁ s₂, R s₁ s₂ →
    ∀ a s₁', sys₁.transition s₁ a = some s₁' →
      ∃ s₂', sys₂.transition s₂ a = some s₂' ∧ R s₁' s₂'

/-- A bisimulation relation between two coalgebras -/
def Bisimulation {Action : Type u} {State₁ : Type v} {State₂ : Type w}
    (sys₁ : ActionSystem Action State₁)
    (sys₂ : ActionSystem Action State₂)
    (R : State₁ → State₂ → Prop) : Prop :=
  Simulation sys₁ sys₂ R ∧ Simulation sys₂ sys₁ (fun s₂ s₁ => R s₁ s₂)

/-! ## Composition -/

/-- Parallel composition of two action systems (interleaving semantics) -/
def ActionSystem.parallel {Action₁ : Type u} {Action₂ : Type v}
    {State₁ : Type w} {State₂ : Type x}
    (sys₁ : ActionSystem Action₁ State₁)
    (sys₂ : ActionSystem Action₂ State₂) :
    ActionSystem (Action₁ ⊕ Action₂) (State₁ × State₂) where
  transition := fun (s₁, s₂) action =>
    match action with
    | .inl a₁ => (sys₁.transition s₁ a₁).map (·, s₂)
    | .inr a₂ => (sys₂.transition s₂ a₂).map (s₁, ·)

end Coalgebra
