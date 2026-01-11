#!/bin/bash

# Test script for TodoMVC Interactive Mode
# This demonstrates the step-by-step mode with various commands

echo "================================================"
echo "Testing TodoMVC Interactive Mode"
echo "================================================"
echo ""

# Test 1: Basic interactive mode with step-by-step
echo "Test 1: Running interactive mode with step-by-step..."
echo "Commands: add, toggle, filter, clear"
echo ""

cat << 'EOF' | lake exe ltl_formal_verification --interactive
add Buy groceries
add Write documentation
add Review pull requests
toggle 0
active
list
clear
all
quit
EOF

echo ""
echo "================================================"
echo ""

# Test 2: Normal mode then enabling step-by-step
echo "Test 2: Enabling step-by-step mode during session..."
echo ""

cat << 'EOF' | lake exe ltl_formal_verification
add First task
add Second task
step on
toggle 0
toggle 1
step off
delete 0
quit
EOF

echo ""
echo "================================================"
echo ""

# Test 3: Verify example trace
echo "Test 3: Running verification on example trace..."
echo ""

lake exe ltl_formal_verification --verify

echo ""
echo "================================================"
echo ""

# Test 4: Run example script
echo "Test 4: Running example script..."
echo ""

lake exe ltl_formal_verification --example

echo ""
echo "================================================"
echo "All tests completed!"
echo "================================================"
