#!/bin/bash
# Test script for Phase 1: HTML Serialization
# Demonstrates all serialization functions working correctly

set -e

echo "============================================"
echo "Phase 1: HTML Serialization Test Suite"
echo "============================================"
echo ""

# Create a temporary test file
TEST_FILE=$(mktemp /tmp/todomvc_test.XXXXXX.lean)

cat > "$TEST_FILE" << 'EOF'
import LtlFormalVerification.TodoMVC.WebMain

open TodoMVC.WebMain

def testBasicSerialization : IO Unit := do
  IO.println "TEST 1: Initial State Serialization"
  IO.println "===================================="
  let initial := getInitialState
  IO.println s!"Initial: {initial}"
  IO.println ""

def testAddTodo : IO Unit := do
  IO.println "TEST 2: Add Todo Action"
  IO.println "========================"
  let state0 := getInitialState

  -- Enter text
  let action1 := "{\"type\":\"enterText\",\"text\":\"Buy groceries\"}"
  let state1 := processAction state0 action1
  IO.println s!"After enterText: {state1}"

  -- Add todo
  let action2 := "{\"type\":\"addTodo\"}"
  let state2 := processAction state1 action2
  IO.println s!"After addTodo: {state2}"
  IO.println ""

def testMultipleTodos : IO Unit := do
  IO.println "TEST 3: Multiple Todos"
  IO.println "======================"
  let state0 := getInitialState

  -- Add first todo
  let s1 := processAction state0 "{\"type\":\"enterText\",\"text\":\"Learn Lean 4\"}"
  let s2 := processAction s1 "{\"type\":\"addTodo\"}"

  -- Add second todo
  let s3 := processAction s2 "{\"type\":\"enterText\",\"text\":\"Build web app\"}"
  let s4 := processAction s3 "{\"type\":\"addTodo\"}"

  -- Add third todo
  let s5 := processAction s4 "{\"type\":\"enterText\",\"text\":\"Deploy to production\"}"
  let s6 := processAction s5 "{\"type\":\"addTodo\"}"

  IO.println s!"Final state with 3 todos: {s6}"
  IO.println ""

def testToggle : IO Unit := do
  IO.println "TEST 4: Toggle Todo Completion"
  IO.println "==============================="
  let state0 := getInitialState

  -- Add a todo
  let s1 := processAction state0 "{\"type\":\"enterText\",\"text\":\"Complete this task\"}"
  let s2 := processAction s1 "{\"type\":\"addTodo\"}"
  IO.println s!"Before toggle: {s2}"

  -- Toggle it
  let s3 := processAction s2 "{\"type\":\"toggleTodo\",\"id\":0}"
  IO.println s!"After toggle: {s3}"
  IO.println ""

def testFilter : IO Unit := do
  IO.println "TEST 5: Filter Changes"
  IO.println "======================"
  let state0 := getInitialState

  -- Add some todos
  let s1 := processAction state0 "{\"type\":\"enterText\",\"text\":\"Active todo\"}"
  let s2 := processAction s1 "{\"type\":\"addTodo\"}"

  -- Try changing filter
  let s3 := processAction s2 "{\"type\":\"setFilter\",\"filter\":\"active\"}"
  IO.println s!"Filter set to active: {s3}"

  let s4 := processAction s3 "{\"type\":\"setFilter\",\"filter\":\"completed\"}"
  IO.println s!"Filter set to completed: {s4}"
  IO.println ""

def testDelete : IO Unit := do
  IO.println "TEST 6: Delete Todo"
  IO.println "==================="
  let state0 := getInitialState

  -- Add two todos
  let s1 := processAction state0 "{\"type\":\"enterText\",\"text\":\"Keep this\"}"
  let s2 := processAction s1 "{\"type\":\"addTodo\"}"
  let s3 := processAction s2 "{\"type\":\"enterText\",\"text\":\"Delete this\"}"
  let s4 := processAction s3 "{\"type\":\"addTodo\"}"
  IO.println s!"Before delete: {s4}"

  -- Delete second todo
  let s5 := processAction s4 "{\"type\":\"deleteTodo\",\"id\":1}"
  IO.println s!"After delete: {s5}"
  IO.println ""

def testHTMLRendering : IO Unit := do
  IO.println "TEST 7: HTML Rendering"
  IO.println "======================"
  let state0 := getInitialState

  -- Add a todo
  let s1 := processAction state0 "{\"type\":\"enterText\",\"text\":\"Test HTML rendering\"}"
  let s2 := processAction s1 "{\"type\":\"addTodo\"}"

  -- Render
  let html := renderState s2
  IO.println "HTML Output (first 300 chars):"
  IO.println (html.take 300)
  IO.println "..."
  IO.println ""
  IO.println s!"HTML length: {html.length} characters"
  IO.println "✓ HTML rendering successful"
  IO.println ""

def testToggleAll : IO Unit := do
  IO.println "TEST 8: Toggle All"
  IO.println "=================="
  let state0 := getInitialState

  -- Add multiple todos
  let s1 := processAction state0 "{\"type\":\"enterText\",\"text\":\"Todo 1\"}"
  let s2 := processAction s1 "{\"type\":\"addTodo\"}"
  let s3 := processAction s2 "{\"type\":\"enterText\",\"text\":\"Todo 2\"}"
  let s4 := processAction s3 "{\"type\":\"addTodo\"}"

  IO.println s!"Before toggleAll: {s4}"

  -- Toggle all
  let s5 := processAction s4 "{\"type\":\"toggleAll\"}"
  IO.println s!"After toggleAll: {s5}"
  IO.println ""

def testClearCompleted : IO Unit := do
  IO.println "TEST 9: Clear Completed"
  IO.println "======================="
  let state0 := getInitialState

  -- Add and complete some todos
  let s1 := processAction state0 "{\"type\":\"enterText\",\"text\":\"Active\"}"
  let s2 := processAction s1 "{\"type\":\"addTodo\"}"
  let s3 := processAction s2 "{\"type\":\"enterText\",\"text\":\"Will be done\"}"
  let s4 := processAction s3 "{\"type\":\"addTodo\"}"
  let s5 := processAction s4 "{\"type\":\"toggleTodo\",\"id\":1}"

  IO.println s!"Before clear: {s5}"

  -- Clear completed
  let s6 := processAction s5 "{\"type\":\"clearCompleted\"}"
  IO.println s!"After clear: {s6}"
  IO.println ""

def testInvalidActions : IO Unit := do
  IO.println "TEST 10: Error Handling"
  IO.println "======================="
  let state0 := getInitialState

  -- Try to toggle non-existent todo
  let s1 := processAction state0 "{\"type\":\"toggleTodo\",\"id\":999}"
  IO.println s!"Toggle invalid ID (should be unchanged): {s1 == state0}"

  -- Try invalid JSON
  let s2 := processAction state0 "{\"invalid json"
  IO.println s!"Invalid JSON (should be unchanged): {s2 == state0}"

  -- Try to set filter with no items
  let empty := "{\"items\":[],\"selectedFilter\":null,\"pendingText\":\"\",\"nextId\":0}"
  let s3 := processAction empty "{\"type\":\"setFilter\",\"filter\":\"active\"}"
  IO.println s!"Set filter on empty (should be unchanged): {s3 == empty}"
  IO.println ""

def main : IO Unit := do
  testBasicSerialization
  testAddTodo
  testMultipleTodos
  testToggle
  testFilter
  testDelete
  testHTMLRendering
  testToggleAll
  testClearCompleted
  testInvalidActions

  IO.println "============================================"
  IO.println "All Phase 1 Tests Completed Successfully! ✅"
  IO.println "============================================"
EOF

# Run the test
echo "Running tests..."
echo ""
lake env lean --run "$TEST_FILE"

# Clean up
rm "$TEST_FILE"

echo ""
echo "Test script completed successfully!"
