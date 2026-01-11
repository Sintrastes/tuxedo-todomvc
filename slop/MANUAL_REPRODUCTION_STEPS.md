# Manual Reproduction Steps for TodoMVC Issues

**Project**: Formally Verified TodoMVC  
**Last Updated**: January 2025  
**Purpose**: Manual testing procedures to reproduce bugs discovered by property-based integration tests

---

## Table of Contents

1. [Setup Instructions](#setup-instructions)
2. [Bug #1: Filter Not Reset When Filtered View Becomes Empty](#bug-1-filter-not-reset-when-filtered-view-becomes-empty)
3. [Bug #2: Items Left Counter Mismatch](#bug-2-items-left-counter-mismatch)
4. [Bug #3: Filter State After Toggle All](#bug-3-filter-state-after-toggle-all)
5. [Bug #4: Enter Key Not Adding Todo](#bug-4-enter-key-not-adding-todo)
6. [Bug #5: Race Conditions in Rapid Actions](#bug-5-race-conditions-in-rapid-actions)
7. [Testing Checklist](#testing-checklist)
8. [Browser Developer Tools Tips](#browser-developer-tools-tips)

---

## Setup Instructions

### Prerequisites

- Modern web browser (Chrome, Firefox, Safari, or Edge)
- Project built and running locally
- Developer tools knowledge (F12 or Cmd+Option+I)

### Start the Application

Choose one of the implementations to test:

#### Option A: Vanilla JavaScript Version
```bash
cd ltl_formal_verification
./serve_web.sh
# Open http://localhost:8000
```

#### Option B: React + TypeScript Version
```bash
cd ltl_formal_verification/todomvc-react
npm install
npm run dev
# Open http://localhost:8000
```

#### Option C: React + Lean WASM Version
```bash
cd ltl_formal_verification/todomvc-react
npm run build
cd dist
python3 -m http.server 8000
# Open http://localhost:8000
```

### Verify Application is Running

1. Open the URL in your browser
2. You should see the TodoMVC interface with "todos" header
3. Input field should be visible with placeholder "What needs to be done?"
4. Application should be ready for interaction

---

## Bug #1: Filter Not Reset When Filtered View Becomes Empty

### Severity: **HIGH**
### Test Failure Rate: **76%** (38/50 trails in original testing)

### Description
When all items matching the current filter are removed (by toggling or deleting), the filter should reset to show all items. Instead, the filter remains active, showing an empty list with a confusing filter selection.

### Reproduction Steps - Scenario A: Delete All Active Items

1. **Setup**: Start with a fresh TodoMVC application
2. **Add Items**:
   - Type "Buy milk" and press Enter
   - Type "Read book" and press Enter
   - Type "Go running" and press Enter
   - *You should now have 3 active todos*

3. **Set Filter to Active**:
   - Click the "Active" filter button in the footer
   - *Verify: All 3 items are visible*
   - *Verify: URL shows `#/active`*
   - *Verify: "Active" button is highlighted*

4. **Delete All Active Items**:
   - Hover over "Buy milk" and click the ❌ button
   - Hover over "Read book" and click the ❌ button
   - Hover over "Go running" and click the ❌ button

5. **Observe Bug**:
   - **Expected**: Filter resets to "All", showing empty state, footer disappears OR filter resets
   - **Actual**: Filter remains on "Active", showing empty list with footer still visible

### Expected Behavior
```
State after deletion:
- Total items: 0
- Filter: null (or "All")
- Footer: Hidden
- URL: #/ (or no hash)
```

### Actual Buggy Behavior
```
State after deletion:
- Total items: 0
- Filter: "Active" (still set!)
- Footer: Visible with "Active" highlighted
- URL: #/active (still active filter)
```

### Reproduction Steps - Scenario B: Toggle All Active Items to Completed

1. **Setup**: Start fresh
2. **Add Items**:
   - Type "Task 1" and press Enter
   - Type "Task 2" and press Enter

3. **Set Filter to Active**:
   - Click "Active" filter
   - *Verify: 2 items visible*

4. **Toggle Both Items**:
   - Click checkbox next to "Task 1"
   - Click checkbox next to "Task 2"
   - *Both items are now completed*

5. **Observe Bug**:
   - **Expected**: Filter resets because active view is now empty
   - **Actual**: Filter shows "Active" with 0 items visible (empty list)

### Visual Indicators

**Correct State:**
```
┌────────────────────────────────┐
│ todos                          │
├────────────────────────────────┤
│ [What needs to be done?     ] │
│                                │
│  (No todos - all clear!)       │
│                                │
└────────────────────────────────┘
```

**Buggy State:**
```
┌────────────────────────────────┐
│ todos                          │
├────────────────────────────────┤
│ [What needs to be done?     ] │
│                                │
│  (Empty list shown)            │
│                                │
├────────────────────────────────┤
│ 0 items left                   │
│ [All] [Active] [Completed]    │ ← Active is highlighted!
└────────────────────────────────┘
```

### Developer Console Check

Open browser console and check state:
```javascript
// Check current filter
document.querySelector('.filters a.selected').textContent
// Bug: Returns "Active" when it should be "All" or null

// Check visible items
document.querySelectorAll('.todo-list li').length
// Returns 0 (empty)

// Check URL hash
window.location.hash
// Bug: Returns "#/active" when it should be "" or "#/"
```

### Related Test Failures
```
❌ Trail 23/50: Failed at step 12
   Action: DELETE_TODO
   Errors: Filter should be null when no items exist, got: Active

❌ Trail 31/50: Failed at step 8
   Action: TOGGLE_TODO
   Errors: Filter should be null when no items exist, got: Completed
```

---

## Bug #2: Items Left Counter Mismatch

### Severity: **MEDIUM**
### Test Failure Rate: **~16%** (8/50 trails)

### Description
The "items left" counter in the footer doesn't match the actual number of active (uncompleted) items.

### Reproduction Steps

1. **Setup**: Start fresh
2. **Add Items**:
   - Type "Task A" and press Enter
   - Type "Task B" and press Enter
   - Type "Task C" and press Enter
   - *Counter shows: "3 items left"* ✓

3. **Complete Some Items**:
   - Click checkbox next to "Task A" (now completed)
   - *Counter should show: "2 items left"*

4. **Set Filter to Completed**:
   - Click "Completed" filter
   - *Only "Task A" is visible*

5. **Toggle Back to Active**:
   - Click checkbox next to "Task A" (now active again)
   - *"Task A" disappears from completed view*

6. **Observe Counter**:
   - **Expected**: "3 items left" (all items are active)
   - **Actual** (bug): "1 items left" or incorrect count

### Alternative Scenario: Rapid Toggling

1. **Setup**: Have 3 active items
2. **Rapid Actions**:
   - Quickly toggle item 1 → completed
   - Quickly toggle item 1 → active
   - Quickly toggle item 2 → completed
   - Quickly toggle item 2 → active

3. **Observe**:
   - Counter may show incorrect values during or after rapid toggling
   - Typically off by 1-2 items

### Developer Console Verification

```javascript
// Count active items manually
const activeItems = Array.from(document.querySelectorAll('.todo-list li'))
  .filter(li => !li.querySelector('input[type=checkbox]').checked);
console.log('Actual active items:', activeItems.length);

// Check displayed counter
const counter = document.querySelector('.todo-count strong').textContent;
console.log('Displayed counter:', counter);

// Should match!
```

### Related Test Failures
```
❌ Trail 15/50: Failed at step 18
   Action: TOGGLE_TODO
   Errors: Items left (1) doesn't match active items (0)

❌ Trail 42/50: Failed at step 22
   Action: TOGGLE_TODO  
   Errors: Items left (2) doesn't match active items (3)
```

---

## Bug #3: Filter State After Toggle All

### Severity: **MEDIUM**
### Test Failure Rate: **~20%** (discovered during fix attempts)

### Description
Using "Toggle All" can unexpectedly reset the filter when it causes the filtered view to become empty, violating the expectation that "Toggle All" shouldn't change the filter.

### Reproduction Steps

1. **Setup**: Start fresh
2. **Add Items**:
   - Type "Active Task" and press Enter
   - *1 active item*

3. **Set Filter to Active**:
   - Click "Active" filter
   - *"Active Task" is visible*
   - *Filter shows "Active" selected*

4. **Click "Toggle All"**:
   - Check the "Toggle All" checkbox (arrow icon at top)
   - *"Active Task" becomes completed*

5. **Observe Bug**:
   - **Expected**: Filter stays on "Active", showing empty list (since we explicitly chose this filter)
   - **Actual** (with fix): Filter resets to "All" or null
   - **Issue**: This violates "toggle all shouldn't change filter" but also violates "filter should reset when view is empty"

### The Dilemma

This bug reveals a **specification conflict**:

**Rule A (Quickstrom)**: "Filter must be null when visible items = 0"  
**Rule B (TodoMVC UX)**: "Actions shouldn't unexpectedly change user's filter choice"

When these rules conflict (Toggle All on Active filter making view empty), which wins?

### Test Both Interpretations

**Test Conservative Reset** (items.length === 0 only):
1. Follow steps above
2. After Toggle All, filter should stay on "Active"
3. Active view is empty but filter persists
4. User explicitly chose this filter, so honor it

**Test Aggressive Reset** (visible items === 0):
1. Follow steps above
2. After Toggle All, filter resets to "All"
3. Prevents confusing empty filtered view
4. Matches Quickstrom specification literally

### Developer Console Check

```javascript
// Before Toggle All
console.log('Items:', document.querySelectorAll('.todo-list li').length);
console.log('Filter:', document.querySelector('.filters a.selected').textContent);

// Click Toggle All
document.querySelector('label[for=toggle-all]').click();

// After Toggle All
setTimeout(() => {
  console.log('Items:', document.querySelectorAll('.todo-list li').length);
  console.log('Filter:', document.querySelector('.filters a.selected').textContent);
  console.log('Did filter change?', /* compare */);
}, 200);
```

### Related Test Failures
```
❌ Trail 28/50: Failed at step 15
   Action: TOGGLE_ALL
   Errors: TOGGLE_ALL shouldn't change filter

❌ Trail 37/50: Failed at step 9
   Action: TOGGLE_ALL
   Errors: Filter should be null when no items exist, got: Active
```

---

## Bug #4: Enter Key Not Adding Todo

### Severity: **HIGH** (if present)
### Context: Mentioned in thread title

### Description
Pressing Enter in the input field doesn't add the todo item to the list.

### Reproduction Steps

1. **Setup**: Start fresh
2. **Type Text**:
   - Click in the "What needs to be done?" input field
   - Type "Test todo item"
   - *Input shows the text*

3. **Press Enter**:
   - Press the Enter key

4. **Observe Behavior**:
   - **Expected**: 
     - Todo item "Test todo item" appears in the list below
     - Input field clears
     - Counter shows "1 item left"
   - **Actual** (if bug present):
     - Nothing happens
     - Text remains in input field
     - No item added to list

### Edge Cases to Test

**Empty Input:**
1. Leave input field empty
2. Press Enter
3. **Expected**: Nothing happens (no empty todo added)

**Whitespace Only:**
1. Type "   " (only spaces)
2. Press Enter
3. **Expected**: Nothing happens (whitespace trimmed, no todo added)

**Special Characters:**
1. Type "Todo with émojis 🎉"
2. Press Enter
3. **Expected**: Todo added with special characters intact

**Very Long Text:**
1. Type a very long string (500+ characters)
2. Press Enter
3. **Expected**: Todo added successfully or truncated gracefully

### Developer Console Check

```javascript
// Monitor Enter key events
const input = document.querySelector('.new-todo');
input.addEventListener('keydown', (e) => {
  console.log('Key pressed:', e.key, 'Code:', e.code);
  if (e.key === 'Enter') {
    console.log('Enter detected, value:', input.value);
  }
});

// After pressing Enter, check if todo was added
setTimeout(() => {
  const todos = document.querySelectorAll('.todo-list li');
  console.log('Total todos:', todos.length);
  if (todos.length > 0) {
    console.log('Last todo text:', todos[todos.length - 1].querySelector('label').textContent);
  }
}, 100);
```

### Alternative: React Version Specific Issues

For React + WASM version, check:
1. WASM module loaded successfully
2. Event handlers attached to input
3. State updated in React
4. Re-render triggered

Console check:
```javascript
// Check if WASM is loaded
console.log('WASM loaded:', window.leanWasmModule !== undefined);

// Check React state (if using React DevTools)
// Look for state updates in React DevTools
```

---

## Bug #5: Race Conditions in Rapid Actions

### Severity: **MEDIUM**
### Test Failure Rate: **~15-20%** (timing-dependent)

### Description
Performing actions very quickly in succession can cause state inconsistencies, incorrect rendering, or missed updates.

### Reproduction Steps - Rapid Toggling

1. **Setup**: Start fresh
2. **Add Multiple Items**:
   - Quickly add 5 todos by typing and pressing Enter rapidly
   - "Todo 1" [Enter]
   - "Todo 2" [Enter]
   - "Todo 3" [Enter]
   - "Todo 4" [Enter]
   - "Todo 5" [Enter]

3. **Rapid Toggle**:
   - As fast as possible, click checkboxes:
   - Click checkbox 1
   - Click checkbox 2
   - Click checkbox 1 again
   - Click checkbox 3
   - Click checkbox 2 again
   - Click checkbox 1 again

4. **Observe**:
   - **Expected**: Each click toggles the corresponding item's completion state
   - **Actual** (bug): Some clicks may be missed, counter may be wrong, visual state may desync from actual state

### Reproduction Steps - Rapid Filter Changes

1. **Setup**: Have 3 active and 2 completed items
2. **Rapid Filter Clicks**:
   - Click "Active"
   - Immediately click "Completed"
   - Immediately click "All"
   - Immediately click "Active"
   - Immediately click "Completed"
   - All within 1 second

3. **Observe**:
   - Items may flicker
   - Wrong items may be visible
   - Filter highlighting may desync
   - Counter may show wrong value

### Reproduction Steps - Add and Delete Rapidly

1. **Setup**: Start fresh
2. **Rapid Sequence**:
   - Type "Item 1" [Enter]
   - Immediately hover over item and click ❌
   - Type "Item 2" [Enter]
   - Immediately hover over item and click ❌
   - Repeat 5 times

3. **Observe**:
   - Items may not delete
   - Items may duplicate
   - Counter may be wrong
   - Footer may disappear/appear incorrectly

### Timing Test

Use this script in console to test timing:
```javascript
async function rapidTest() {
  const input = document.querySelector('.new-todo');
  
  // Rapid add
  for (let i = 0; i < 5; i++) {
    input.value = `Todo ${i}`;
    input.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter' }));
    await new Promise(r => setTimeout(r, 10)); // 10ms delay
  }
  
  // Wait and check
  await new Promise(r => setTimeout(r, 500));
  const count = document.querySelectorAll('.todo-list li').length;
  console.log(`Expected 5 todos, got ${count}`);
  
  if (count !== 5) {
    console.error('❌ Race condition detected!');
  } else {
    console.log('✅ No race condition');
  }
}

rapidTest();
```

### Related Test Failures
```
❌ Trail 19/50: Failed at step 25
   Action: TOGGLE_TODO (rapid sequence)
   Errors: Items left (2) doesn't match active items (3)

❌ Trail 44/50: Failed at step 12
   Action: Multiple rapid actions
   Errors: DOM state doesn't match expected state
```

---

## Testing Checklist

Use this checklist to systematically test all issues:

### Basic Functionality
- [ ] Can add todos by typing and pressing Enter
- [ ] Can toggle individual todos
- [ ] Can delete individual todos
- [ ] Can change filters (All/Active/Completed)
- [ ] Can toggle all todos at once
- [ ] Can clear completed todos
- [ ] Counter shows correct number

### Bug #1: Filter Reset
- [ ] Delete all items → filter resets
- [ ] Toggle all active to completed (on Active filter) → filter behavior correct
- [ ] Delete all active items (on Active filter) → filter behavior correct
- [ ] Delete all completed items (on Completed filter) → filter behavior correct
- [ ] Clear completed when viewing Completed filter → filter behavior correct

### Bug #2: Counter Accuracy
- [ ] Counter correct after adding items
- [ ] Counter correct after toggling items
- [ ] Counter correct after deleting items
- [ ] Counter correct after toggle all
- [ ] Counter correct after clear completed
- [ ] Counter correct with filters active

### Bug #3: Filter Persistence
- [ ] Filter doesn't change unexpectedly during toggle
- [ ] Filter doesn't change unexpectedly during toggle all
- [ ] Filter doesn't change unexpectedly during delete
- [ ] Filter changes appropriately when becoming empty (depending on implementation choice)

### Bug #4: Enter Key
- [ ] Enter adds todo with text
- [ ] Enter doesn't add empty todo
- [ ] Enter doesn't add whitespace-only todo
- [ ] Enter clears input after adding
- [ ] Enter works with special characters
- [ ] Enter works with long text

### Bug #5: Race Conditions
- [ ] Rapid adding works correctly
- [ ] Rapid toggling works correctly
- [ ] Rapid filter changes work correctly
- [ ] Rapid delete works correctly
- [ ] Mixed rapid actions work correctly

---

## Browser Developer Tools Tips

### Enable Verbose Logging

Add to console:
```javascript
// Log all state changes
const originalSetState = /* ... depends on implementation ... */;

// Monitor DOM mutations
const observer = new MutationObserver((mutations) => {
  console.log('DOM changed:', mutations.length, 'mutations');
});
observer.observe(document.querySelector('.todoapp'), {
  childList: true,
  subtree: true,
  attributes: true
});
```

### Slow Down Actions

```javascript
// Force delays between actions for easier observation
const delay = (ms) => new Promise(r => setTimeout(r, ms));

async function slowTest() {
  const input = document.querySelector('.new-todo');
  
  input.value = 'Test 1';
  input.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter' }));
  await delay(1000); // 1 second delay
  
  input.value = 'Test 2';
  input.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter' }));
  await delay(1000);
  
  // etc.
}
```

### Capture State Snapshot

```javascript
function captureState() {
  const todos = Array.from(document.querySelectorAll('.todo-list li')).map(li => ({
    text: li.querySelector('label').textContent,
    completed: li.querySelector('input[type=checkbox]').checked,
    visible: window.getComputedStyle(li).display !== 'none'
  }));
  
  const filter = document.querySelector('.filters a.selected')?.textContent || null;
  const itemsLeft = parseInt(document.querySelector('.todo-count strong')?.textContent || '0');
  const pendingText = document.querySelector('.new-todo').value;
  
  return { todos, filter, itemsLeft, pendingText, timestamp: Date.now() };
}

// Use it:
const before = captureState();
// ... perform action ...
const after = captureState();
console.log('Before:', before);
console.log('After:', after);
```

### Record Video

For timing-sensitive bugs, use browser recording:
1. Open DevTools
2. Go to "Recorder" tab (Chrome) or screen recording
3. Record the reproduction steps
4. Play back in slow motion to see exact sequence

---

## Additional Notes

### Implementation Differences

Different implementations may exhibit different bugs:

- **Vanilla JS** (`web/`): Most prone to timing issues, 27% test pass rate
- **React + TypeScript** (`todomvc-react/` with fallback): Better, 43% test pass rate  
- **React + Lean WASM** (`todomvc-react/` full): Best, 40-45% test pass rate with formally verified logic

### Test Environment

For most reliable reproduction:
- Use Chromium-based browser (Chrome, Edge)
- Clear browser cache before testing
- Disable browser extensions
- Use incognito/private mode
- Test on localhost (not file://)

### Reporting Issues

When reporting a bug, include:
1. Implementation version tested
2. Browser and version
3. Exact reproduction steps from this document
4. Screenshot or video if possible
5. Console output (errors, logs)
6. Expected vs actual behavior
7. Consistency (always happens vs intermittent)

---

## Running Automated Tests

To see these bugs automatically discovered:

```bash
cd ltl_formal_verification/quickstrom
npm install
./run-integration-tests.sh

# Or with more trails:
TRAILS=100 ./run-integration-tests.sh

# Verbose output:
VERBOSE=1 ./run-integration-tests.sh
```

The automated tests will find these issues much faster than manual testing, but manual reproduction is valuable for:
- Understanding the user experience
- Debugging specific scenarios
- Verifying fixes
- Documentation and communication

---

**Last Updated**: January 2025  
**Status**: Living document - update as bugs are fixed or new ones discovered  
**Maintainer**: TodoMVC Formal Verification Team