# TodoMVC Testing Quick Reference

**Quick guide for testing and reproducing bugs in the formally verified TodoMVC application**

---

## 🚀 Quick Start

```bash
# Start the app (choose one):
./serve_web.sh                    # Vanilla JS
cd todomvc-react && npm run dev   # React
cd quickstrom && ./run-integration-tests.sh  # Automated tests
```

Open: http://localhost:8000

---

## 🐛 Bug Quick Reference

### Bug #1: Filter Not Reset (HIGH Priority) ⚠️
**What**: Filter stays active when filtered view becomes empty  
**Test**: Add 3 todos → Set "Active" filter → Delete all → Filter stays "Active"  
**Expected**: Filter resets to "All" or null  
**Test Pass Rate**: 24% (76% fail)

### Bug #2: Counter Mismatch (MEDIUM Priority)
**What**: "Items left" counter doesn't match actual active items  
**Test**: Add 3 todos → Toggle one → Check counter  
**Expected**: Counter equals unchecked items  
**Test Pass Rate**: 84% (16% fail)

### Bug #3: Toggle All Changes Filter (MEDIUM Priority)
**What**: Toggle All unexpectedly resets filter  
**Test**: 1 active item → "Active" filter → Toggle All → Filter changes  
**Expected**: (Debated - see specification conflict)  
**Test Pass Rate**: 80% (20% fail)

### Bug #4: Enter Key Not Working (HIGH Priority if present)
**What**: Pressing Enter doesn't add todo  
**Test**: Type "Test" → Press Enter → Nothing happens  
**Expected**: Todo added, input cleared  
**Test Pass Rate**: Implementation-specific

### Bug #5: Race Conditions (MEDIUM Priority)
**What**: Rapid actions cause state corruption  
**Test**: Rapidly add/toggle/delete 10 times → Check consistency  
**Expected**: All actions processed correctly  
**Test Pass Rate**: 80-85% (15-20% fail)

---

## ⚡ 30-Second Tests

### Test #1: Basic Filter Reset
```
1. Add 3 todos (Enter key each)
2. Click "Active" filter
3. Delete all 3 todos (click X)
4. CHECK: Filter should reset, not stay "Active"
```

### Test #2: Counter Accuracy
```
1. Add 2 todos
2. Check first todo (completed)
3. CHECK: Counter shows "1 item left"
4. Uncheck first todo
5. CHECK: Counter shows "2 items left"
```

### Test #3: Toggle All Behavior
```
1. Add 1 todo
2. Click "Active" filter
3. Click toggle-all checkbox
4. CHECK: What happens to filter?
```

### Test #4: Enter Key
```
1. Type "Hello World"
2. Press Enter
3. CHECK: Todo appears, input clears
```

### Test #5: Rapid Actions
```
1. Rapidly add 5 todos (fast typing + Enter)
2. CHECK: All 5 appear
3. Rapidly toggle all 5 checkboxes
4. CHECK: All toggles work, counter correct
```

---

## 🔍 Console Checks

### Check Current State
```javascript
// Quick state snapshot
const state = {
  filter: document.querySelector('.filters a.selected')?.textContent,
  totalItems: document.querySelectorAll('.todo-list li').length,
  visibleItems: Array.from(document.querySelectorAll('.todo-list li'))
    .filter(li => window.getComputedStyle(li).display !== 'none').length,
  activeItems: Array.from(document.querySelectorAll('.todo-list li'))
    .filter(li => !li.querySelector('input[type=checkbox]').checked).length,
  counter: document.querySelector('.todo-count strong')?.textContent,
  hash: window.location.hash
};
console.table(state);
```

### Monitor Actions
```javascript
// Log all clicks and key presses
document.querySelector('.todoapp').addEventListener('click', e => {
  console.log('Click:', e.target.className, e.target.textContent);
});

document.querySelector('.new-todo').addEventListener('keydown', e => {
  if (e.key === 'Enter') {
    console.log('Enter pressed, value:', e.target.value);
  }
});
```

### Check for Mismatches
```javascript
// Verify counter accuracy
const counter = parseInt(document.querySelector('.todo-count strong')?.textContent || '0');
const actual = Array.from(document.querySelectorAll('.todo-list li'))
  .filter(li => !li.querySelector('input[type=checkbox]').checked).length;
console.log(counter === actual ? '✅ Counter correct' : `❌ Mismatch: ${counter} vs ${actual}`);
```

---

## 🎯 Visual Indicators

### Correct Behavior
```
✅ Filter resets when last item deleted
✅ Counter matches active item count
✅ Enter key adds todos
✅ No empty list with active filter
✅ Rapid actions all processed
```

### Bug Indicators
```
❌ "Active" filter with 0 items visible
❌ Counter shows wrong number
❌ Enter key does nothing
❌ Empty list but footer still showing
❌ Actions seem to be skipped
```

---

## 📊 Test Pass Rates by Implementation

| Implementation | Pass Rate | Key Issues |
|---------------|-----------|------------|
| Vanilla JS | 27% | Timing, filter reset, race conditions |
| React + TS | 43% | Filter logic, some timing |
| React + WASM | 40-45% | Minor timing (logic verified!) |

**Note**: Lower pass rate doesn't mean implementation is worse - it means tests are finding issues!

---

## 🛠️ Debug Commands

### Slow Down Time (for manual testing)
```javascript
const delay = ms => new Promise(r => setTimeout(r, ms));

async function slowAdd(text) {
  const input = document.querySelector('.new-todo');
  input.value = text;
  await delay(500);
  input.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter' }));
  await delay(500);
}

// Usage: slowAdd('Test todo').then(() => console.log('Added!'));
```

### Stress Test
```javascript
async function stressTest() {
  for (let i = 0; i < 20; i++) {
    const input = document.querySelector('.new-todo');
    input.value = `Todo ${i}`;
    input.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter' }));
    await new Promise(r => setTimeout(r, 50));
  }
  console.log('Added 20 todos');
  
  // Rapid toggle
  const checkboxes = document.querySelectorAll('.todo-list input[type=checkbox]');
  checkboxes.forEach((cb, i) => {
    setTimeout(() => cb.click(), i * 20);
  });
}
```

### Capture Evidence
```javascript
function screenshot() {
  const state = {
    timestamp: new Date().toISOString(),
    todos: Array.from(document.querySelectorAll('.todo-list li')).map(li => ({
      text: li.querySelector('label').textContent,
      completed: li.querySelector('input[type=checkbox]').checked
    })),
    filter: document.querySelector('.filters a.selected')?.textContent,
    counter: document.querySelector('.todo-count strong')?.textContent,
    url: window.location.href
  };
  console.log(JSON.stringify(state, null, 2));
  return state;
}
```

---

## 🔄 Automated Testing

### Run Integration Tests
```bash
cd quickstrom
npm install
./run-integration-tests.sh

# Quick (10 trails)
TRAILS=10 ./run-integration-tests.sh

# Standard (50 trails)
./run-integration-tests.sh

# Extensive (200 trails)
TRAILS=200 ./run-integration-tests.sh

# Verbose
VERBOSE=1 ./run-integration-tests.sh
```

### Expected Output
```
🧪 TodoMVC Property-Based Integration Testing
============================================================
Configuration:
  URL: http://localhost:8000
  Trails: 50
  Max actions per trail: 30
============================================================

✅ Trail 1/50: Passed (23 actions)
❌ Trail 2/50: Failed at step 12
   Action: DELETE_TODO
   Errors: Filter should be null when no items exist, got: Active
...
```

---

## 📋 Testing Checklist

Quick checklist for manual testing session:

```
Basic Actions:
[ ] Add todo via Enter key
[ ] Toggle todo completion
[ ] Delete todo
[ ] Change filter
[ ] Toggle all
[ ] Clear completed

Bug #1 (Filter Reset):
[ ] Delete all active (on Active filter)
[ ] Delete all completed (on Completed filter)
[ ] Toggle all to completed (on Active filter)

Bug #2 (Counter):
[ ] Add items, check counter
[ ] Toggle items, check counter
[ ] Delete items, check counter

Bug #3 (Toggle All):
[ ] Toggle All with Active filter
[ ] Toggle All with Completed filter

Bug #4 (Enter Key):
[ ] Add normal todo
[ ] Try empty todo
[ ] Try whitespace-only todo

Bug #5 (Race Conditions):
[ ] Rapid add (10 quick items)
[ ] Rapid toggle (all items fast)
[ ] Rapid filter changes
```

---

## 🎓 Key Concepts

### Filter State Rules
- **Conservative**: Reset only when `items.length === 0`
- **Aggressive**: Reset when `visibleItems.length === 0`
- **Conflict**: Quickstrom spec vs UX conventions

### Test Timing
- Vanilla JS: Most timing issues
- React: Better, batched updates
- WASM: Logic correct, UI timing matters

### Specification Conflict
```
Rule A: "Filter must be null when no visible items"
Rule B: "Actions shouldn't change filter unexpectedly"

These conflict when an action causes visible items to become 0!
```

---

## 📞 Getting Help

### Documentation
- Full details: `MANUAL_REPRODUCTION_STEPS.md`
- Integration testing: `INTEGRATION_TESTING.md`
- Bug fixes: `quickstrom/BUG_FIX_SUMMARY.md`

### Console Help
```javascript
// Get this help in console
fetch('/TESTING_QUICK_REFERENCE.md').then(r => r.text()).then(console.log);
```

### Report Bug Format
```
1. Implementation: [Vanilla JS / React / WASM]
2. Browser: [Chrome 120 / Firefox 121 / etc]
3. Steps: [Numbered list]
4. Expected: [What should happen]
5. Actual: [What actually happened]
6. Screenshot: [If possible]
7. Console errors: [Copy paste]
```

---

## 🚦 Pass/Fail Criteria

### PASS ✅
- Filter resets appropriately
- Counter always matches active items
- All actions complete successfully
- No console errors
- State remains consistent

### FAIL ❌
- Filter stuck on "Active" with no items
- Counter mismatches active count
- Actions ignored or skipped
- Console errors present
- State corruption observed

---

**Version**: 1.0  
**Last Updated**: January 2025  
**For detailed reproduction**: See `MANUAL_REPRODUCTION_STEPS.md`
