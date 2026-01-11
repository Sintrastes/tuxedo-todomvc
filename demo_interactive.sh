#!/bin/bash

# TodoMVC Interactive Mode Demo
# This script demonstrates the step-by-step mode with detailed transitions

clear

echo "╔════════════════════════════════════════════════════════╗"
echo "║                                                        ║"
echo "║   TodoMVC - Formally Verified Edition                 ║"
echo "║   Interactive Step-by-Step Mode Demo                  ║"
echo "║                                                        ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "This demo showcases how the interactive mode helps you:"
echo "  • Understand state transitions"
echo "  • See formal verification in action"
echo "  • Learn about invariants and temporal logic"
echo ""
echo "Press Enter to start the demo..."
read

clear
echo "════════════════════════════════════════════════════════"
echo "DEMO 1: Basic Operations with Step-by-Step Mode"
echo "════════════════════════════════════════════════════════"
echo ""
echo "We'll add some tasks, toggle them, and see how the state"
echo "changes while maintaining formal invariants."
echo ""
echo "Commands to execute:"
echo "  1. add Buy groceries"
echo "  2. add Write documentation"
echo "  3. add Review pull requests"
echo "  4. toggle 0"
echo "  5. toggle 1"
echo ""
echo "Press Enter to run..."
read

cat << 'EOF' | lake exe ltl_formal_verification --interactive
add Buy groceries
add Write documentation
add Review pull requests
toggle 0
toggle 1
quit
EOF

echo ""
echo "Press Enter to continue..."
read

clear
echo "════════════════════════════════════════════════════════"
echo "DEMO 2: Filtering and Invariant Checking"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Now we'll demonstrate filtering (all/active/completed)"
echo "and see how the invariant is maintained:"
echo "  Invariant: totalItems = 0 ∨ selectedFilter.isSome"
echo ""
echo "This means: Either there are no items, OR a filter is selected."
echo "This ensures the UI is always in a consistent state."
echo ""
echo "Commands to execute:"
echo "  1. add Task one"
echo "  2. add Task two"
echo "  3. add Task three"
echo "  4. toggle 0"
echo "  5. active (show only active tasks)"
echo "  6. completed (show only completed tasks)"
echo "  7. all (show all tasks)"
echo ""
echo "Press Enter to run..."
read

cat << 'EOF' | lake exe ltl_formal_verification --interactive
add Task one
add Task two
add Task three
toggle 0
active
completed
all
quit
EOF

echo ""
echo "Press Enter to continue..."
read

clear
echo "════════════════════════════════════════════════════════"
echo "DEMO 3: Toggle All and Clear Completed"
echo "════════════════════════════════════════════════════════"
echo ""
echo "This demonstrates bulk operations:"
echo "  • toggleall - marks all as complete (or incomplete)"
echo "  • clear - removes all completed items"
echo ""
echo "Watch how the invariant is maintained even during"
echo "complex state transitions!"
echo ""
echo "Commands to execute:"
echo "  1. add First task"
echo "  2. add Second task"
echo "  3. add Third task"
echo "  4. toggleall (complete all)"
echo "  5. clear (remove completed)"
echo ""
echo "Press Enter to run..."
read

cat << 'EOF' | lake exe ltl_formal_verification --interactive
add First task
add Second task
add Third task
toggleall
clear
quit
EOF

echo ""
echo "Press Enter to continue..."
read

clear
echo "════════════════════════════════════════════════════════"
echo "DEMO 4: Undo Functionality"
echo "════════════════════════════════════════════════════════"
echo ""
echo "The system maintains a history of states, allowing you"
echo "to explore different execution paths."
echo ""
echo "Commands to execute:"
echo "  1. add Task A"
echo "  2. add Task B"
echo "  3. toggle 0"
echo "  4. undo (go back before toggle)"
echo "  5. delete 0 (different path - delete instead)"
echo ""
echo "Press Enter to run..."
read

cat << 'EOF' | lake exe ltl_formal_verification --interactive
add Task A
add Task B
toggle 0
undo
delete 0
quit
EOF

echo ""
echo "Press Enter to continue..."
read

clear
echo "════════════════════════════════════════════════════════"
echo "DEMO 5: Toggling Step-by-Step Mode On and Off"
echo "════════════════════════════════════════════════════════"
echo ""
echo "You can toggle the detailed mode during a session."
echo "This is useful when you want to focus on specific"
echo "transitions without clutter."
echo ""
echo "Commands to execute:"
echo "  1. step off (disable detailed mode)"
echo "  2. add Quick task"
echo "  3. toggle 0"
echo "  4. step on (enable detailed mode)"
echo "  5. add Another task"
echo "  6. toggle 1"
echo ""
echo "Press Enter to run..."
read

cat << 'EOF' | lake exe ltl_formal_verification --interactive
step off
add Quick task
toggle 0
step on
add Another task
toggle 1
quit
EOF

echo ""
echo "Press Enter for final summary..."
read

clear
echo "╔════════════════════════════════════════════════════════╗"
echo "║                                                        ║"
echo "║                   DEMO COMPLETE!                       ║"
echo "║                                                        ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "What you just saw:"
echo ""
echo "✓ State transitions with formal verification"
echo "✓ Invariant checking on every operation"
echo "✓ Linear Temporal Logic properties in action"
echo "✓ Coalgebraic state machine execution"
echo ""
echo "Key insights:"
echo ""
echo "1. INVARIANTS are maintained across ALL transitions"
echo "   The property (totalItems = 0 ∨ selectedFilter.isSome)"
echo "   was checked and verified on every state change."
echo ""
echo "2. STATE TRANSITIONS are explicit and traceable"
echo "   Every action showed before/after states and changes."
echo ""
echo "3. FORMAL VERIFICATION provides mathematical guarantees"
echo "   The system can't enter invalid states - proven by Lean!"
echo ""
echo "4. INTERACTIVE MODE aids understanding"
echo "   Step-by-step execution reveals how formal methods work."
echo ""
echo "════════════════════════════════════════════════════════"
echo ""
echo "Try it yourself:"
echo "  lake exe ltl_formal_verification --interactive"
echo ""
echo "Or learn more:"
echo "  • Read INTERACTIVE_MODE.md for detailed guide"
echo "  • Check README.md for architecture overview"
echo "  • Explore LtlFormalVerification/TodoMVC/*.lean for proofs"
echo ""
echo "Additional commands:"
echo "  lake exe ltl_formal_verification --verify"
echo "    → Verify a pre-defined trace against specifications"
echo ""
echo "  lake exe ltl_formal_verification --example"
echo "    → Run a non-interactive example script"
echo ""
echo "════════════════════════════════════════════════════════"
echo "Thank you for watching this demo!"
echo "════════════════════════════════════════════════════════"
