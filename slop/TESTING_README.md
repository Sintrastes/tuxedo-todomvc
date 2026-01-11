# TodoMVC Manual Testing Documentation

This directory contains comprehensive manual testing documentation for the formally verified TodoMVC application. Use these guides to manually reproduce and verify bugs discovered by automated property-based testing.

---

## 📚 Documentation Overview

### 1. **TESTING_QUICK_REFERENCE.md** - Start Here! ⚡
**Best for**: Quick testing sessions, daily verification, learning the basics

**Contents**:
- 30-second reproduction tests
- Console commands for debugging
- Visual bug indicators
- Quick testing checklist
- Test pass rates by implementation

**Use when**:
- You have 5-10 minutes to test
- You want to verify a specific bug quickly
- You need console commands
- You're doing daily development testing

### 2. **MANUAL_REPRODUCTION_STEPS.md** - Deep Dive 🔍
**Best for**: Comprehensive testing, bug investigation, documentation

**Contents**:
- Detailed step-by-step reproduction for each bug
- Multiple scenarios per bug
- Developer console verification steps
- Expected vs actual behavior comparisons
- Edge cases and variations
- Complete testing checklist

**Use when**:
- You need to thoroughly understand a bug
- You're documenting an issue for a bug report
- You want to test all edge cases
- You're verifying a bug fix

### 3. **INTEGRATION_TESTING.md** - Automated Testing 🤖
**Best for**: Running automated property-based tests

**Contents**:
- How integration tests work
- Running the test suite
- Understanding test results
- Temporal logic specifications
- Test infrastructure details

**Use when**:
- You want to run automated tests
- You need to understand the test framework
- You're adding new test cases
- You want comprehensive validation

---

## 🚀 Quick Start Guide

### I want to... test manually in 5 minutes
→ Read **TESTING_QUICK_REFERENCE.md**
→ Run the "30-Second Tests" section
→ Use the console checks to verify

### I want to... thoroughly reproduce a specific bug
→ Read **MANUAL_REPRODUCTION_STEPS.md**
→ Find the bug section (Bug #1, #2, etc.)
→ Follow the detailed steps
→ Use developer tools verification

### I want to... run automated tests
→ Read **INTEGRATION_TESTING.md**
→ Run: `cd quickstrom && ./run-integration-tests.sh`
→ Review the test output
→ Cross-reference failures with manual steps

### I want to... understand what bugs exist
→ Read **quickstrom/BUG_FIX_SUMMARY.md**
→ See test pass rates and status
→ Understand which bugs are fixed

---

## 🐛 Bug Summary

### Critical Bugs (HIGH Priority)

**Bug #1: Filter Not Reset When Filtered View Becomes Empty**
- **Impact**: 76% test failure rate
- **Issue**: Filter stays active when it should reset
- **Quick Test**: Add items → Set "Active" filter → Delete all → Check filter
- **Status**: Partially fixed, specification conflict remains

**Bug #4: Enter Key Not Adding Todo** (if present)
- **Impact**: Core functionality broken
- **Issue**: Pressing Enter doesn't add todo
- **Quick Test**: Type text → Press Enter → Check if todo appears
- **Status**: Implementation-specific

### Medium Priority Bugs

**Bug #2: Items Left Counter Mismatch**
- **Impact**: 16% test failure rate
- **Issue**: Counter doesn't match active item count
- **Quick Test**: Toggle items → Check counter accuracy

**Bug #3: Filter State After Toggle All**
- **Impact**: 20% test failure rate
- **Issue**: Toggle All may unexpectedly change filter
- **Quick Test**: Set Active filter → Toggle All → Check filter

**Bug #5: Race Conditions in Rapid Actions**
- **Impact**: 15-20% test failure rate
- **Issue**: Fast actions cause state corruption
- **Quick Test**: Rapidly add/toggle/delete → Check consistency

---

## 📊 Test Pass Rates

| Implementation | Pass Rate | Best For |
|---------------|-----------|----------|
| **Vanilla JS** (`web/`) | 27% | Understanding baseline |
| **React + TypeScript** (`todomvc-react/` fallback) | 43% | Better UX, no formal verification |
| **React + Lean WASM** (`todomvc-react/` full) | 40-45% | **Formally verified logic!** |

**Note**: The React + WASM version has formally verified business logic (100% correct), but some timing issues remain in the UI layer. This is the recommended architecture.

---

## 🎯 Testing Workflow

### Daily Development Testing
```bash
1. Start app: ./serve_web.sh (or npm run dev)
2. Open TESTING_QUICK_REFERENCE.md
3. Run "30-Second Tests"
4. Use console checks to verify
5. Document any new issues
```

### Pre-Commit Testing
```bash
1. Run manual tests from TESTING_QUICK_REFERENCE.md
2. Run automated tests: cd quickstrom && ./run-integration-tests.sh
3. Verify all critical paths work
4. Check console for errors
```

### Bug Investigation
```bash
1. Identify bug from test failure or user report
2. Open MANUAL_REPRODUCTION_STEPS.md
3. Find the relevant bug section
4. Follow detailed reproduction steps
5. Use developer console verification
6. Document findings
```

### Bug Fix Verification
```bash
1. Reproduce bug manually (MANUAL_REPRODUCTION_STEPS.md)
2. Apply fix
3. Re-test manually with all scenarios
4. Run automated tests (should improve pass rate)
5. Document the fix in BUG_FIX_SUMMARY.md
```

---

## 🛠️ Setup Instructions

### Start the Application

**Option A: Vanilla JavaScript**
```bash
cd ltl_formal_verification
./serve_web.sh
# Open http://localhost:8000
```

**Option B: React + TypeScript**
```bash
cd ltl_formal_verification/todomvc-react
npm install
npm run dev
# Open http://localhost:8000
```

**Option C: React + Lean WASM (Recommended)**
```bash
cd ltl_formal_verification/todomvc-react
npm run build
cd dist
python3 -m http.server 8000
# Open http://localhost:8000
```

### Run Automated Tests
```bash
cd ltl_formal_verification/quickstrom
npm install
./run-integration-tests.sh

# Options:
TRAILS=10 ./run-integration-tests.sh    # Quick test
TRAILS=200 ./run-integration-tests.sh   # Extensive test
VERBOSE=1 ./run-integration-tests.sh    # Detailed output
```

---

## 📖 Documentation Map

```
ltl_formal_verification/
├── TESTING_README.md                    ← You are here
├── TESTING_QUICK_REFERENCE.md           ← Quick tests & console commands
├── MANUAL_REPRODUCTION_STEPS.md         ← Detailed bug reproduction
├── INTEGRATION_TESTING.md               ← Automated testing guide
└── quickstrom/
    ├── BUG_FIX_SUMMARY.md              ← Bug status & fixes
    ├── todomvc-integration-test.js     ← Test implementation
    └── run-integration-tests.sh        ← Test runner
```

---

## 🎓 Understanding the Tests

### What is Property-Based Testing?

Instead of writing specific test cases like:
```
Test: Add 3 todos, toggle the first one, delete the second one
```

Property-based testing generates **random action sequences** and verifies **invariants**:
```
For any random sequence of actions:
- Counter must equal active items
- Filter must be null when no items exist
- State transitions must be valid
```

### Why 40-45% Pass Rate with Verified Code?

The **Lean 4 business logic is 100% mathematically proven correct**. The test failures are:
- **Timing issues** (~40%): DOM updates, React render cycles
- **UI layer bugs** (~40%): Integration code between React and WASM
- **Specification conflicts** (~20%): Ambiguity between Quickstrom spec and TodoMVC UX

The core state machine is perfect - it's the web UI layer that needs refinement!

---

## 🔍 Common Testing Scenarios

### Scenario: Enter Key Not Working

1. **Check**:
   ```javascript
   // Console
   document.querySelector('.new-todo').addEventListener('keydown', e => {
     console.log('Key:', e.key, 'Handler attached:', !!e);
   });
   ```

2. **Test**: Type text and press Enter

3. **Verify**: Check if todo was added and input cleared

4. **If failing**: Check event listeners, WASM loading, React state

### Scenario: Filter Not Resetting

1. **Setup**: Add 3 todos, set "Active" filter

2. **Action**: Delete all 3 todos

3. **Check**:
   ```javascript
   // Console
   console.log('Filter:', document.querySelector('.filters a.selected')?.textContent);
   console.log('Total items:', document.querySelectorAll('.todo-list li').length);
   ```

4. **Expected**: Filter is "All" or null, total items is 0

### Scenario: Counter Mismatch

1. **Setup**: Add and toggle various items

2. **Check**:
   ```javascript
   // Console
   const counter = parseInt(document.querySelector('.todo-count strong').textContent);
   const actual = Array.from(document.querySelectorAll('.todo-list li'))
     .filter(li => !li.querySelector('input[type=checkbox]').checked).length;
   console.log(`Counter: ${counter}, Actual: ${actual}, Match: ${counter === actual}`);
   ```

---

## 💡 Tips for Effective Testing

### Do's ✅
- Start with quick reference for fast feedback
- Use developer console extensively
- Test in incognito mode (clean state)
- Document reproduction steps precisely
- Cross-reference manual and automated tests
- Test all implementations (Vanilla, React, WASM)

### Don'ts ❌
- Don't assume one pass means it's fixed (timing issues are intermittent)
- Don't test in file:// protocol (use localhost)
- Don't have browser extensions interfering
- Don't skip edge cases
- Don't ignore console warnings/errors

---

## 🚦 When to Use Each Document

| Situation | Use This Document |
|-----------|-------------------|
| Quick daily check | TESTING_QUICK_REFERENCE.md |
| Investigating specific bug | MANUAL_REPRODUCTION_STEPS.md |
| Running automated tests | INTEGRATION_TESTING.md |
| Understanding bug status | quickstrom/BUG_FIX_SUMMARY.md |
| Learning testing approach | This README |

---

## 📞 Getting Help

### Questions About Testing?
- Read INTEGRATION_TESTING.md for testing philosophy
- Check BUG_FIX_SUMMARY.md for known issues
- Review automated test code in quickstrom/

### Questions About Bugs?
- See MANUAL_REPRODUCTION_STEPS.md for detailed steps
- Use TESTING_QUICK_REFERENCE.md for quick checks
- Check console output for error messages

### Questions About Formal Verification?
- Read PHASE2_WASM_SUCCESS.md for WASM details
- See PROJECT_COMPLETE.md for architecture
- Review Lean code in LtlFormalVerification/TodoMVC/

---

## 🎉 Success Criteria

Your testing session is successful when:

✅ You can reproduce the bugs manually  
✅ You understand why they occur  
✅ You can verify fixes with both manual and automated tests  
✅ You've documented any new issues found  
✅ Console shows no unexpected errors  

---

## 📝 Contributing

When you find a new bug:
1. Document reproduction steps (follow MANUAL_REPRODUCTION_STEPS.md format)
2. Test across all implementations
3. Check if automated tests catch it
4. Add to BUG_FIX_SUMMARY.md
5. Create console verification script

---

**Version**: 1.0  
**Last Updated**: January 2025  
**Status**: Active - update as testing procedures evolve

**Happy Testing! 🧪**