# Code Organization

This document describes the organization of the TodoMVC formal verification codebase.

## Overview

The codebase is organized to clearly separate formal proofs from runtime verification machinery and interactive tools. The main focus is on the formal proofs of correctness.

## Module Structure

### Core Formal Verification Modules

#### `LtlFormalVerification/LTL.lean`
Defines Linear Temporal Logic (LTL) formulas and semantics over traces.
- Formula constructors: `atom`, `neg`, `conj`, `disj`, `impl`, `next`, `always`, `eventually`, `until`
- Satisfaction relation for traces
- Core to all formal specifications

#### `LtlFormalVerification/Coalgebra.lean`
Defines the coalgebraic/action system framework for modeling state transitions.
- `ActionSystem`: Transition systems with actions
- `Execution`: Sequences of states and actions
- `Invariant`: Properties preserved by transitions
- `Observer`: Observable behavior abstraction (for future use)
- Core to modeling the TodoMVC implementation

#### `LtlFormalVerification/TodoMVC/Spec.lean`
The formal LTL specification translated from the Quickstrom spec.
- State predicates and transition predicates
- `initialState`: Initial state conditions
- `validTransition`: Valid state transitions
- `hasFiltersInvariant`: Main invariant (items exist → filter shown)
- `todoMVCSpec`: Complete LTL specification
- **Axiom**: `initial_none_filter_implies_empty` - semantic constraint that initial states with no filter must have no items
- **Note**: Contains only specifications and axioms, no proofs (proofs are in Proofs.lean)

#### `LtlFormalVerification/TodoMVC/App.lean`
The TodoMVC implementation modeled as an action system.
- `TodoState`: Application state structure
- `Action`: User actions (addTodo, toggleTodo, setFilter, etc.)
- `todoActionSystem`: The transition system
- State operations: `addItem`, `toggleItem`, `deleteItem`, etc.
- **Note**: Dead code removed (ObservableState, executeActions, exampleExecution)
- **Note**: Proofs moved to Proofs.lean (addItem_preserves_invariant)

#### `LtlFormalVerification/TodoMVC/Proofs.lean`
**Formal proofs of correctness** - the main contribution.
- Initial state validity proofs:
  - `impl_initial_satisfies_spec`
  - `impl_initial_satisfies_invariant`
  - `initial_satisfies_invariant` (general theorem)
- Invariant preservation proofs for each transition type:
  - `enterText_preserves_invariant`
  - `addItem_preserves_invariant`
  - `setFilter_preserves_invariant`
  - `toggleItem_preserves_invariant`
  - `deleteItem_preserves_invariant`
  - `toggleAllItems_preserves_invariant`
  - `clearCompleted_preserves_invariant`
- Main theorems:
  - `deleteItem_preserves_invariant`
  - `clearCompleted_preserves_invariant`
  - `checked_counts_consistent`
  - `execution_satisfies_always_invariant`
  - `system_satisfies_invariant`
  - `todoMVC_valid_traces`
- All `sorry` stubs have been filled in!
</text>

<old_text line=173>
## File Sizes (Approximate)

- `Proofs.lean`: ~250 lines (all proofs complete, no `sorry`)
- `Spec.lean`: ~330 lines (formal specification + 1 axiom)

### Runtime and Interactive Modules

#### `LtlFormalVerification/TodoMVC/Verification.lean` ⭐ NEW
Runtime verification machinery separated from proofs.
- `checkInvariant`: Decidable runtime check of the invariant
- `ExecutionTrace`: Recording of execution traces
- `verifyTrace`: Check if a trace satisfies invariants
- `TraceCommand`: Command representation for trace recording
- `verifyTraceDetailed`: Detailed verification with violation detection
- Example traces for testing

**Purpose**: This module contains all the runtime verification code that was previously mixed with the driver. It's separate from the formal proofs but can be used for testing and runtime checking.

#### `LtlFormalVerification/TodoMVC/Driver.lean`
Interactive CLI driver for the TodoMVC application.
- REPL for interactive use
- Command parsing and execution
- Step-by-step mode showing transitions
- **Removed**: `runExample`, `verifyExample`, trace recording (moved to Verification.lean)
- **Kept**: Interactive modes, display functions, REPL loop

#### `LtlFormalVerification/TodoMVC/View.lean`
Abstract view/rendering layer (kept for future use).
- HTML-like representation structure
- View model and rendering functions
- Observer instances
- **Status**: Not currently used by Driver or Proofs, but kept for future web frontend

#### `Main.lean`
Entry point for the executable.
- **Removed**: `--example` and `--verify` command-line options
- **Kept**: Interactive REPL modes (`--interactive` and default)

## What Changed in the Reorganization

### 1. Runtime Verification Separated
All runtime verification machinery moved from `Driver.lean` to new `Verification.lean`:
- `checkInvariant`
- `ExecutionTrace` structure
- `recordTrace` and `verifyTrace` functions
- Example trace definitions

### 2. Commands Removed
The following non-interactive commands were removed:
- `--example` command (ran example script)
- `--verify` command (verified example trace)
- `runExample` and `verifyExample` functions

### 3. Dead Code Removed
From `App.lean`:
- `ObservableState` structure (unused)
- `todoObserver` (unused)
- `executeActions` and `executeWithHistory` (replaced by Driver's REPL)
- `exampleExecution` (moved to Verification in different form)
- `initial_state_valid` and `empty_state_valid` theorems (redundant with Proofs.lean)

### 4. Unused Imports Removed
- `View` import removed from `Driver.lean` (not used)
- View module kept but not imported anywhere (for future use)

## Module Dependencies

```
LTL.lean
  └─> Coalgebra.lean
        ├─> TodoMVC/Spec.lean
        │     └─> TodoMVC/App.lean
        │           ├─> TodoMVC/Proofs.lean ⭐ (formal proofs)
        │           ├─> TodoMVC/Verification.lean (runtime)
        │           ├─> TodoMVC/Driver.lean (interactive)
        │           └─> TodoMVC/View.lean (future use)
        └─> TodoMVC/View.lean (uses Observer)
```

## Usage

### Formal Verification (Main Purpose)
The formal proofs are in `Proofs.lean`. To verify correctness:
```bash
lake build LtlFormalVerification.TodoMVC.Proofs
```

### Interactive Use
```bash
lake build
.lake/build/bin/ltl_formal_verification          # Start REPL
.lake/build/bin/ltl_formal_verification -i        # Step-by-step mode
```

### Runtime Verification (For Testing)
Import `LtlFormalVerification.TodoMVC.Verification` to use runtime checking:
```lean
import LtlFormalVerification.TodoMVC.Verification
open TodoMVC.Verification

def myTrace := recordTrace [.add "Test", .toggle 0]
#eval verifyTraceDetailed myTrace
```

## Key Theorems

The main correctness results are:

1. **Initial Validity**: `impl_initial_satisfies_spec` and `impl_initial_satisfies_invariant`
2. **Invariant Preservation**: All operations preserve `hasFiltersInvariant`
3. **System Correctness**: `system_satisfies_invariant` - the system always satisfies the invariant
4. **Trace Validity**: `todoMVC_valid_traces` - all executions from initial state are valid

## Design Principles

1. **Separation of Concerns**: Formal proofs, runtime verification, and interactive tools are in separate modules
2. **Proof-Focused**: The main value is in the formal proofs, not the runtime checking
3. **Minimalism**: Dead code removed, only essential functionality kept
4. **Future-Proof**: View layer kept for future web frontend despite not being used currently
5. **Usability**: Interactive REPL retained for demonstration and exploration

## File Sizes (Actual)

- `Proofs.lean`: 314 lines (all proofs complete, no `sorry`)
- `Spec.lean`: 308 lines (formal specification + 1 axiom, no proofs)
- `App.lean`: 183 lines (implementation, dead code and proofs removed)
- `Verification.lean`: 125 lines (runtime verification)
- `Driver.lean`: 320 lines (interactive REPL)
- `View.lean`: 182 lines (for future use)