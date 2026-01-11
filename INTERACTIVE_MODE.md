# Interactive Mode Guide

## Overview

The TodoMVC Formally Verified Edition includes an **interactive step-by-step mode** that allows you to explore how the application state evolves with each action, while simultaneously showing how formal verification properties are maintained.

This mode is perfect for:
- Understanding how the TodoMVC state machine works
- Learning about formal verification concepts
- Debugging application behavior
- Seeing how invariants are preserved across state transitions

## Starting Interactive Mode

There are two ways to start the interactive mode:

### 1. Launch Directly in Step-by-Step Mode

```bash
lake exe ltl_formal_verification --interactive
# or
lake exe ltl_formal_verification -i
```

This starts the application with step-by-step mode already enabled, showing detailed transition information for every action.

### 2. Enable Within Normal REPL

```bash
lake exe ltl_formal_verification
```

Then at the prompt, type:
```
todo> step on
```

You can toggle it off with:
```
todo> step off
```

## Available Commands

### Todo Management
- `add <text>` - Add a new todo item
- `toggle <id>` - Toggle completion status of item with given ID
- `delete <id>` - Delete an item (aliases: `del`, `rm`)
- `toggleall` - Toggle all items (complete all if any incomplete, else uncomplete all)
- `clear` - Clear all completed items

### Filtering
- `all` - Show all items
- `active` - Show only active (incomplete) items
- `completed` - Show only completed items (alias: `done`)

### Navigation and Control
- `list` - Show current state (aliases: `ls`, `show`)
- `undo` - Undo the last action
- `step [on|off]` - Toggle step-by-step detailed mode
- `help` - Show help (aliases: `h`, `?`)
- `quit` - Exit the program (aliases: `exit`, `q`)

## Understanding Step-by-Step Output

When step-by-step mode is enabled, each action produces detailed output showing:

### Action Information
```
⚡ Action: toggleTodo(0)
```
Shows the exact action being performed with its parameters.

### State Comparison
```
  Before: 3 items, 2 active, filter=some all
  After:  3 items, 1 active, filter=some all
```
Displays key state metrics before and after the transition.

### Changes Summary
```
  Changes: (-1 active)
```
Highlights what changed in the transition (items added/removed, active count changes, filter changes).

### Invariant Checking
```
✓ Invariant: MAINTAINED (totalItems = 0 ∨ selectedFilter.isSome)
```

Shows whether the core application invariant is preserved:
- **The invariant**: Either there are no items (totalItems = 0), OR a filter is selected (selectedFilter.isSome)
- **Why it matters**: This ensures the UI is always in a consistent state - you can only view items if a filter is active
- **✓ MAINTAINED**: The property holds in both before and after states
- **⚠ Warning**: The property was already violated before this action
- **✗ VIOLATED**: The action broke the invariant (should not happen in correct implementation)

## Example Session

Here's a complete example session demonstrating the interactive mode:

```
╔═══════════════════════════════════════╗
║   TodoMVC - Formally Verified Edition  ║
║        STEP-BY-STEP MODE ACTIVE        ║
║   All transitions will show details    ║
╚═══════════════════════════════════════╝

╔═══════════════════════════╗
║         TODOS             ║
╠═══════════════════════════╣
║  (no items)               ║
╠═══════════════════════════╣
║ 0 items left              ║
║ [All] Active Completed    ║
╚═══════════════════════════╝
todo> add Buy groceries

─────────────────────────────
⚡ Action: addTodo
  Before: 0 items, 0 active, filter=some all
  After:  1 items, 1 active, filter=some all
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
todo> add Write documentation

─────────────────────────────
⚡ Action: addTodo
  Before: 1 items, 1 active, filter=some all
  After:  2 items, 2 active, filter=some all
  Changes: (+1 items) (+1 active)
✓ Invariant: MAINTAINED (totalItems = 0 ∨ selectedFilter.isSome)
─────────────────────────────
Added: Write documentation

todo> toggle 0

─────────────────────────────
⚡ Action: toggleTodo(0)
  Before: 2 items, 2 active, filter=some all
  After:  2 items, 1 active, filter=some all
  Changes: (-1 active)
✓ Invariant: MAINTAINED (totalItems = 0 ∨ selectedFilter.isSome)
─────────────────────────────
Toggled item 0

todo> active

─────────────────────────────
⚡ Action: setFilter(active)
  Before: 2 items, 1 active, filter=some all
  After:  2 items, 1 active, filter=some active
  Changes: (filter changed: some all → some active)
✓ Invariant: MAINTAINED (totalItems = 0 ∨ selectedFilter.isSome)
─────────────────────────────
Filter set to active

╔═══════════════════════════╗
║         TODOS             ║
╠═══════════════════════════╣
║ 1: [ ] Write documentat.. ║
╠═══════════════════════════╣
║ 1 items left              ║
║ All [Active] Completed    ║
╚═══════════════════════════╝
todo> clear

─────────────────────────────
⚡ Action: clearCompleted
  Before: 2 items, 1 active, filter=some active
  After:  1 items, 1 active, filter=some active
  Changes: (-1 items)
✓ Invariant: MAINTAINED (totalItems = 0 ∨ selectedFilter.isSome)
─────────────────────────────
Cleared completed items

todo> undo
Undone

todo> quit
Goodbye!
```

## Educational Value

### For Learning Formal Verification

The interactive mode demonstrates several formal verification concepts:

1. **State Machines**: Each action is a state transition in a formally defined state machine
2. **Invariants**: Properties that must hold in every reachable state
3. **Preconditions**: Some actions are only enabled in certain states (e.g., can't toggle a non-existent item)
4. **Observable Behavior**: The view is a pure function of the state (no hidden state)

### For Understanding LTL Specifications

While the interactive mode shows invariants (safety properties), the full codebase includes Linear Temporal Logic (LTL) specifications that express:

- **Always** (□): Properties that must hold in all future states
- **Eventually** (◇): Properties that must eventually become true
- **Next** (○): Properties about the immediate next state
- **Until** (𝒰): Properties that hold until another becomes true

The invariant shown in step-by-step mode is equivalent to the LTL formula: `□(totalItems = 0 ∨ selectedFilter.isSome)`

## Tips and Tricks

### Exploring State Transitions

1. Start with simple operations:
   ```
   add First task
   add Second task
   toggle 0
   ```

2. Observe how the invariant is maintained even after complex operations:
   ```
   toggleall
   clear
   undo
   ```

3. Try operations that fail and see how the state remains unchanged:
   ```
   toggle 999    # Non-existent ID
   delete 999    # Non-existent ID
   ```

### Understanding Filters

1. Start with no items and try to change filter (will fail):
   ```
   active        # "Cannot change filter (no items)"
   ```

2. Add items, then change filters:
   ```
   add Task one
   active        # Now works!
   ```

3. See how visible items change based on filter:
   ```
   all           # Shows all items
   toggle 0
   active        # Hides the completed item
   completed     # Shows only completed items
   ```

### Using Undo

The undo feature lets you explore alternative execution paths:

```
add Task 1
add Task 2
toggle 0
undo          # Back before toggle
delete 0      # Different path - delete instead
```

## Integration with Formal Proofs

The interactive mode executes the same formally verified code that is proven correct in `TodoMVC/Proofs.lean`. Key proven properties include:

- **Initial State Validity**: The initial state satisfies all invariants
- **Transition Preservation**: Valid state transitions preserve invariants
- **Trace Properties**: Sequences of actions satisfy temporal specifications

Every action you perform in interactive mode is backed by mathematical proofs ensuring correctness!

## Advanced Usage

### Scripting

You can create scripts and pipe them into the application:

```bash
echo -e "add Task 1\nadd Task 2\ntoggle 0\nlist" | lake exe ltl_formal_verification
```

### Verification

Run the built-in verification:

```bash
lake exe ltl_formal_verification --verify
```

This executes a predefined trace and verifies all states satisfy the invariant.

### Custom Traces

Modify the `exampleScript` in `TodoMVC/Driver.lean` to create custom test scenarios.

## Troubleshooting

### Command Not Recognized

If you type a command and get "Unknown command":
- Type `help` to see all available commands
- Check spelling and spacing (e.g., `toggleall` not `toggle all`)

### Item ID Not Found

Item IDs are auto-generated starting from 0. Use the `list` command to see current IDs:
```
todo> list
```

### Invariant Warnings

If you see invariant warnings, this indicates a bug in the implementation. The formal proofs guarantee this should not happen in the verified code paths!

## Next Steps

- Explore the formal specifications in `LtlFormalVerification/TodoMVC/Spec.lean`
- Read the proofs in `LtlFormalVerification/TodoMVC/Proofs.lean`
- Study the LTL framework in `LtlFormalVerification/LTL.lean`
- Examine the coalgebraic modeling in `LtlFormalVerification/Coalgebra.lean`

## Contributing

Have ideas for improving the interactive mode? Consider adding:
- Visualization of the state transition graph
- Property-based testing integration
- More detailed LTL property checking
- Interactive proof exploration

See the main README for contribution guidelines.