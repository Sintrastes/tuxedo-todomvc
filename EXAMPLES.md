# TodoMVC Interactive Mode - Examples

This document provides real-world examples of using the TodoMVC Formally Verified Edition's interactive mode.

## Table of Contents

- [Quick Start](#quick-start)
- [Example 1: Basic Todo Operations](#example-1-basic-todo-operations)
- [Example 2: Understanding Invariants](#example-2-understanding-invariants)
- [Example 3: Filter Operations](#example-3-filter-operations)
- [Example 4: Bulk Operations](#example-4-bulk-operations)
- [Example 5: Exploring with Undo](#example-5-exploring-with-undo)
- [Example 6: Toggling Step Mode](#example-6-toggling-step-mode)
- [Example 7: Error Handling](#example-7-error-handling)

## Quick Start

Launch the interactive step-by-step mode:

```bash
lake exe ltl_formal_verification --interactive
```

Or start in normal mode and enable step-by-step later:

```bash
lake exe ltl_formal_verification
todo> step on
```

## Example 1: Basic Todo Operations

This example demonstrates adding tasks and marking them complete.

### Commands
```
add Buy groceries
add Write report
toggle 0
list
quit
```

### Expected Output (in step-by-step mode)

```
╔═══════════════════════════╗
║         TODOS             ║
╠═══════════════════════════╣
║  (no items)               ║
╠═══════════════════════════╣
║ 0 items left              ║
║ [All] Active Completed    ║
╚═══════════════════════════╝
todo> 
─────────────────────────────
⚡ Action: addTodo
  Before: 0 items, 0 active, filter=(some All)
  After:  1 items, 1 active, filter=(some All)
  Changes: (+1 items) (+1 active)
✓ Invariant: MAINTAINED (totalItems = 0 ∨ selectedFilter.isSome)
─────────────────────────────
Added: Buy groceries

╔═══════════════════════════╗
║         TODOS             ║
╠═══════════════════════════╣
║ 0: [ ] Buy groceries      ║
╠═══════════════════════════╣
║ 1 items left              ║
║ [All] Active Completed    ║
╚═══════════════════════════╝
todo> 
─────────────────────────────
⚡ Action: addTodo
  Before: 1 items, 1 active, filter=(some All)
  After:  2 items, 2 active, filter=(some All)
  Changes: (+1 items) (+1 active)
✓ Invariant: MAINTAINED (totalItems = 0 ∨ selectedFilter.isSome)
─────────────────────────────
Added: Write report

╔═══════════════════════════╗
║         TODOS             ║
╠═══════════════════════════╣
║ 0: [ ] Buy groceries      ║
║ 1: [ ] Write report       ║
╠═══════════════════════════╣
║ 2 items left              ║
║ [All] Active Completed    ║
╚═══════════════════════════╝
todo> 
─────────────────────────────
⚡ Action: toggleTodo(0)
  Before: 2 items, 2 active, filter=(some All)
  After:  2 items, 1 active, filter=(some All)
  Changes: (-1 active)
✓ Invariant: MAINTAINED (totalItems = 0 ∨ selectedFilter.isSome)
─────────────────────────────
Toggled item 0

╔═══════════════════════════╗
║         TODOS             ║
╠═══════════════════════════╣
║ 0: [✓] Buy groceries      ║
║ 1: [ ] Write report       ║
╠═══════════════════════════╣
║ 1 items left              ║
║ [All] Active Completed    ║
╚═══════════════════════════╝
```

### What's Happening

1. **Starting state**: Empty list with "All" filter selected (initial state)
2. **First add**: Creates item with ID 0, increases total and active counts
3. **Second add**: Creates item with ID 1, increases counts again
4. **Toggle**: Marks item 0 as complete, reducing active count by 1
5. **Invariant**: After each operation, the system verifies that the core invariant holds

The invariant `totalItems = 0 ∨ selectedFilter.isSome` ensures that whenever items exist, a filter must be selected. This keeps the UI in a consistent state.

## Example 2: Understanding Invariants

This example explores what the invariant means and why it's important.

### Commands
```
add First task
all
active
completed
clear
quit
```

### Key Observations

When you **add the first item**:
```
Before: 0 items, 0 active, filter=(some All)
After:  1 items, 1 active, filter=(some All)
```
- The system automatically sets filter to "All" when transitioning from 0 to 1 items
- This maintains the invariant: `selectedFilter.isSome` becomes true

When you **clear all items**:
```
Before: 1 items, 0 active, filter=(some All)
After:  0 items, 0 active, filter=(none)
```
- If all items are removed, the filter may become `none`
- The invariant still holds: `totalItems = 0` is true

### Why This Matters

The invariant prevents invalid states like:
- Having items but no filter selected (UI wouldn't know what to display)
- Being in a state where rendering is ambiguous

This is a **safety property** expressed in Linear Temporal Logic as: `□(totalItems = 0 ∨ selectedFilter.isSome)`

Where `□` (box) means "always" - the property must hold in every reachable state.

## Example 3: Filter Operations

Demonstrates filtering between all, active, and completed items.

### Commands
```
add Task A
add Task B
add Task C
toggle 0
toggle 1
active
completed
all
quit
```

### What Each Filter Shows

After toggling items 0 and 1, you have:
- 3 total items
- 2 completed items (0, 1)
- 1 active item (2)

**Filter: active**
```
╔═══════════════════════════╗
║         TODOS             ║
╠═══════════════════════════╣
║ 2: [ ] Task C             ║
╠═══════════════════════════╣
║ 1 items left              ║
║ All [Active] Completed    ║
╚═══════════════════════════╝
```
Shows only uncompleted items.

**Filter: completed**
```
╔═══════════════════════════╗
║         TODOS             ║
╠═══════════════════════════╣
║ 0: [✓] Task A             ║
║ 1: [✓] Task B             ║
╠═══════════════════════════╣
║ 1 items left              ║
║ All Active [Completed]    ║
╚═══════════════════════════╝
```
Shows only completed items.

**Filter: all**
```
╔═══════════════════════════╗
║         TODOS             ║
╠═══════════════════════════╣
║ 0: [✓] Task A             ║
║ 1: [✓] Task B             ║
║ 2: [ ] Task C             ║
╠═══════════════════════════╣
║ 1 items left              ║
║ [All] Active Completed    ║
╚═══════════════════════════╝
```
Shows all items regardless of completion status.

### State Transition Example

When switching from "all" to "active":
```
─────────────────────────────
⚡ Action: setFilter(Active)
  Before: 3 items, 1 active, filter=(some All)
  After:  3 items, 1 active, filter=(some Active)
  Changes: (filter changed: some All → some Active)
✓ Invariant: MAINTAINED (totalItems = 0 ∨ selectedFilter.isSome)
─────────────────────────────
```

Note: The total items and active count don't change - only which items are visible in the view.

## Example 4: Bulk Operations

Demonstrates `toggleall` and `clear` commands.

### Commands
```
add Task 1
add Task 2
add Task 3
toggleall
clear
quit
```

### Toggle All Behavior

When **no items are completed**, `toggleall` marks all as complete:
```
─────────────────────────────
⚡ Action: toggleAll
  Before: 3 items, 3 active, filter=(some All)
  After:  3 items, 0 active, filter=(some All)
  Changes: (-3 active)
✓ Invariant: MAINTAINED (totalItems = 0 ∨ selectedFilter.isSome)
─────────────────────────────
```

When **all items are completed**, `toggleall` marks all as incomplete:
```
─────────────────────────────
⚡ Action: toggleAll
  Before: 3 items, 0 active, filter=(some All)
  After:  3 items, 3 active, filter=(some All)
  Changes: (+3 active)
✓ Invariant: MAINTAINED (totalItems = 0 ∨ selectedFilter.isSome)
─────────────────────────────
```

### Clear Completed

The `clear` command removes all completed items:
```
─────────────────────────────
⚡ Action: clearCompleted
  Before: 3 items, 0 active, filter=(some All)
  After:  0 items, 0 active, filter=(none)
  Changes: (-3 items)
✓ Invariant: MAINTAINED (totalItems = 0 ∨ selectedFilter.isSome)
─────────────────────────────
```

Notice: When all items are removed, the filter becomes `none`, but the invariant still holds because `totalItems = 0`.

## Example 5: Exploring with Undo

Use undo to explore different execution paths.

### Commands
```
add Task X
add Task Y
toggle 0
undo
delete 0
list
quit
```

### Timeline

1. **State after adding both tasks**:
   - Items: [Task X (active), Task Y (active)]
   - Active: 2

2. **State after toggle 0**:
   - Items: [Task X (completed), Task Y (active)]
   - Active: 1

3. **State after undo** (reverts to step 1):
   - Items: [Task X (active), Task Y (active)]
   - Active: 2

4. **State after delete 0** (different path from step 1):
   - Items: [Task Y (active)]
   - Active: 1

### Use Cases for Undo

- **Exploring alternatives**: Try different operations without restarting
- **Testing verification**: See how different paths maintain invariants
- **Learning**: Understand how actions affect state
- **Debugging**: Step backwards through execution

### Important Note

Undo works with the **state history**, not action history. You can't "redo" - once you take a new action after undo, the future history is lost.

## Example 6: Toggling Step Mode

Control the verbosity of output during a session.

### Commands
```
step on
add Detailed task
toggle 0
step off
add Quick task
delete 0
step on
list
quit
```

### Output Comparison

**With step-by-step mode ON**:
```
─────────────────────────────
⚡ Action: addTodo
  Before: 0 items, 0 active, filter=(some All)
  After:  1 items, 1 active, filter=(some All)
  Changes: (+1 items) (+1 active)
✓ Invariant: MAINTAINED (totalItems = 0 ∨ selectedFilter.isSome)
─────────────────────────────
Added: Detailed task
```

**With step-by-step mode OFF**:
```
Added: Quick task
```

### When to Use Each Mode

**Step-by-step mode ON**:
- Learning how the system works
- Debugging unexpected behavior
- Verifying invariants
- Understanding state transitions
- Educational demonstrations

**Step-by-step mode OFF**:
- Normal usage
- Quick task management
- When output is too verbose
- Batch operations

## Example 7: Error Handling

See how the system handles invalid operations.

### Commands
```
toggle 999
delete 999
active
add Task
toggle 999
quit
```

### Error Messages

**Trying to toggle non-existent item**:
```
todo> toggle 999
Item 999 not found
```
State remains unchanged.

**Trying to change filter with no items**:
```
todo> active
Cannot change filter (no items)
```
The precondition `!s.items.isEmpty` fails.

**After adding an item, same ID still not found**:
```
todo> toggle 999
Item 999 not found
```
Item was created with ID 0, not 999.

### Failed Operations in Step-by-Step Mode

When step-by-step is enabled, failed operations don't show transition details:
```
todo> toggle 999
Item 999 not found
```

No action transition is shown because `todoActionSystem.transition` returns `none` when the precondition fails. This is **correct behavior** - the system won't attempt invalid state transitions.

### Formal Verification Guarantee

The fact that these operations fail gracefully (state unchanged) is guaranteed by the formal verification. The action system's `transition` function is proven to only produce valid states:

```lean
transition : State → Action → Option State
```

If an action can't be performed, it returns `none` rather than producing an invalid state.

## Running These Examples

### Interactive Execution

Start the application and type commands manually:
```bash
lake exe ltl_formal_verification --interactive
```

### Scripted Execution

Create a file with commands (one per line) and pipe it:
```bash
cat << 'EOF' | lake exe ltl_formal_verification --interactive
add Task 1
add Task 2
toggle 0
quit
EOF
```

### Using Echo

For quick tests:
```bash
printf "add Test\ntoggle 0\nquit\n" | lake exe ltl_formal_verification --interactive
```

## Advanced: Understanding the Verification

### What's Being Verified

Every transition shows:
```
✓ Invariant: MAINTAINED (totalItems = 0 ∨ selectedFilter.isSome)
```

This checks that after the action, the state satisfies the key invariant. The full verification (in `Proofs.lean`) proves:

1. **Initial state validity**: `TodoState.initial` satisfies the invariant
2. **Preservation**: Every valid transition preserves the invariant
3. **Always holds**: Therefore, `□(invariant)` is true for all reachable states

### LTL Formula

The invariant is expressed as an LTL formula:
```lean
always (atom hasFiltersInvariant)
```

Where:
- `always` (□) means "in all future states"
- `atom` lifts a state predicate to a formula
- `hasFiltersInvariant` is the predicate `totalItems = 0 ∨ selectedFilter.isSome`

### Coalgebraic Modeling

The system is modeled as a coalgebra:
```lean
def todoActionSystem : ActionSystem Action TodoState where
  transition := fun s action => ...
```

This functional approach makes the system:
- **Deterministic**: Same state + action = same result
- **Pure**: No hidden side effects
- **Verifiable**: Can be reasoned about mathematically

## Learning Resources

After trying these examples, explore:

1. **INTERACTIVE_MODE.md** - Complete guide to interactive mode
2. **README.md** - Architecture and theoretical background
3. **LtlFormalVerification/LTL.lean** - LTL implementation
4. **LtlFormalVerification/TodoMVC/Spec.lean** - Full specification
5. **LtlFormalVerification/TodoMVC/Proofs.lean** - Formal proofs

## Contributing Examples

Have an interesting use case? Consider adding it to this document! Useful examples include:

- Edge cases that reveal interesting behavior
- Workflows that demonstrate verification concepts
- Scenarios that help explain formal methods
- Comparisons with unverified implementations

See the main README for contribution guidelines.