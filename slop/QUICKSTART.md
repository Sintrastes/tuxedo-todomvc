# Quick Start: TodoMVC Interactive Mode

Get started with the formally verified TodoMVC in under 5 minutes!

## Installation & Building

```bash
cd ltl_formal_verification
lake build
```

## Launch Interactive Mode

```bash
lake exe ltl_formal_verification --interactive
```

You should see:
```
╔═══════════════════════════════════════╗
║   TodoMVC - Formally Verified Edition  ║
║        STEP-BY-STEP MODE ACTIVE        ║
║   All transitions will show details    ║
╚═══════════════════════════════════════╝
```

## Your First Todo

Type these commands at the `todo>` prompt:

```
add Buy groceries
```

**What you'll see:**
- ⚡ The action being performed
- 📊 State before and after
- 📈 What changed
- ✓ Invariant verification

## Try These Common Tasks

### Adding Multiple Items
```
add Write report
add Call dentist
add Review code
```

### Marking Items Complete
```
toggle 0
toggle 2
```
*IDs start at 0*

### Filtering Views
```
active      # Show only incomplete items
completed   # Show only completed items
all         # Show everything
```

### Bulk Operations
```
toggleall   # Complete all (or uncomplete all)
clear       # Remove all completed items
```

### Undo Mistakes
```
undo        # Go back one step
```

### Getting Help
```
help        # See all commands
```

## Understanding the Output

When you perform an action, you'll see:

```
─────────────────────────────
⚡ Action: toggleTodo(0)
  Before: 2 items, 2 active, filter=(some All)
  After:  2 items, 1 active, filter=(some All)
  Changes: (-1 active)
✓ Invariant: MAINTAINED (totalItems = 0 ∨ selectedFilter.isSome)
─────────────────────────────
```

This shows:
1. **Action**: What operation was performed
2. **Before/After**: State comparison
3. **Changes**: What specifically changed
4. **Invariant**: Mathematical proof that the state is valid

## The Invariant Explained

**Invariant**: `totalItems = 0 ∨ selectedFilter.isSome`

This means: Either there are no items, OR a filter is selected.

**Why it matters**: This ensures the UI is always in a consistent state. You can't have items without knowing which ones to display!

This property is mathematically proven to hold after EVERY operation. That's the power of formal verification! 🎉

## Toggle Step-by-Step Mode

You can turn detailed mode on/off anytime:

```
step off    # Disable detailed transitions
step on     # Enable detailed transitions
```

## Exit

```
quit
```
(or use: `exit`, `q`)

## Quick Reference

| Command | Action |
|---------|--------|
| `add <text>` | Add a new todo |
| `toggle <id>` | Mark complete/incomplete |
| `delete <id>` | Remove an item |
| `all` | Show all items |
| `active` | Show incomplete items only |
| `completed` | Show completed items only |
| `toggleall` | Toggle all items |
| `clear` | Clear completed items |
| `undo` | Undo last action |
| `step on/off` | Toggle detailed mode |
| `help` | Show all commands |
| `quit` | Exit |

## Other Modes

### Normal REPL (no step-by-step)
```bash
lake exe ltl_formal_verification
```

### Run Example Script
```bash
lake exe ltl_formal_verification --example
```

### Verify Example Trace
```bash
lake exe ltl_formal_verification --verify
```

### Show Help
```bash
lake exe ltl_formal_verification --help
```

## Next Steps

- 📖 **[INTERACTIVE_MODE.md](INTERACTIVE_MODE.md)** - Complete guide with advanced features
- 📝 **[EXAMPLES.md](EXAMPLES.md)** - Real session examples and use cases
- 🏗️ **[README.md](README.md)** - Architecture and formal verification details

## What Makes This Special?

Unlike regular todo apps, this one is **formally verified**:

- ✅ **Mathematically proven** to satisfy its specification
- ✅ **Impossible** to reach invalid states (proof guaranteed!)
- ✅ **LTL specifications** express temporal properties
- ✅ **Coalgebraic modeling** provides clean semantics
- ✅ **Interactive verification** - see proofs in action!

Every operation you perform is backed by mathematical proofs in Lean 4. The system literally *cannot* violate its invariants - it's proven impossible!

## Troubleshooting

**Q: Command not found**
```
Type 'help' to see all commands
```

**Q: Can't toggle item**
```
Use 'list' to see item IDs (they start at 0)
```

**Q: Too much output**
```
Type 'step off' to disable detailed mode
```

**Q: Want to see more details**
```
Type 'step on' to enable detailed mode
```

## Have Fun!

You're now exploring a formally verified application with mathematical guarantees about its correctness. Enjoy the confidence that comes with knowing your software is provably correct! 🚀
