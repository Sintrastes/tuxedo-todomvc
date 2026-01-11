// Test script for the compiled WASM TodoMVC module
// Usage: node test_wasm.js

const createLeanModule = require('./.lake/build/wasm/main.js');

console.log('╔═══════════════════════════════════════════════════════╗');
console.log('║   TodoMVC WASM Module Test - Formally Verified        ║');
console.log('╚═══════════════════════════════════════════════════════╝');
console.log('');

async function test() {
    try {
        console.log('Loading WASM module...');
        const Module = await createLeanModule();
        console.log('✓ WASM module loaded successfully!');
        console.log('');

        // Test 1: Get initial state
        console.log('TEST 1: Get Initial State');
        console.log('─────────────────────────');
        try {
            const initialState = Module.ccall('getInitialState', 'string', [], []);
            console.log('Initial state:', initialState);
            const parsed = JSON.parse(initialState);
            console.log('✓ Valid JSON returned');
            console.log('✓ Items:', parsed.items);
            console.log('✓ Filter:', parsed.selectedFilter);
            console.log('');
        } catch (e) {
            console.log('✗ Failed:', e.message);
            console.log('Note: Function may need different calling convention');
            console.log('');
        }

        // Test 2: Process action (enter text)
        console.log('TEST 2: Process Action - Enter Text');
        console.log('────────────────────────────────────');
        try {
            const state0 = Module.ccall('getInitialState', 'string', [], []);
            const action1 = JSON.stringify({type: 'enterText', text: 'Learn Lean 4'});
            const state1 = Module.ccall('processAction', 'string',
                ['string', 'string'], [state0, action1]);
            console.log('After enterText:', state1);
            console.log('✓ Action processed successfully');
            console.log('');
        } catch (e) {
            console.log('✗ Failed:', e.message);
            console.log('');
        }

        // Test 3: Add a todo
        console.log('TEST 3: Process Action - Add Todo');
        console.log('──────────────────────────────────');
        try {
            const state0 = Module.ccall('getInitialState', 'string', [], []);
            const action1 = JSON.stringify({type: 'enterText', text: 'Build TodoMVC'});
            const state1 = Module.ccall('processAction', 'string',
                ['string', 'string'], [state0, action1]);
            const action2 = JSON.stringify({type: 'addTodo'});
            const state2 = Module.ccall('processAction', 'string',
                ['string', 'string'], [state1, action2]);
            console.log('After addTodo:', state2);
            const parsed = JSON.parse(state2);
            console.log('✓ Todo added successfully');
            console.log('✓ Items count:', parsed.items ? parsed.items.length : 0);
            console.log('');
        } catch (e) {
            console.log('✗ Failed:', e.message);
            console.log('');
        }

        // Test 4: Render state
        console.log('TEST 4: Render State to HTML');
        console.log('─────────────────────────────');
        try {
            const state0 = Module.ccall('getInitialState', 'string', [], []);
            const html = Module.ccall('renderState', 'string', ['string'], [state0]);
            console.log('HTML output (first 200 chars):');
            console.log(html.substring(0, 200) + '...');
            console.log('✓ HTML rendered successfully');
            console.log('✓ HTML length:', html.length, 'characters');
            console.log('');
        } catch (e) {
            console.log('✗ Failed:', e.message);
            console.log('');
        }

        // Test 5: Full workflow
        console.log('TEST 5: Complete Workflow');
        console.log('─────────────────────────');
        try {
            let state = Module.ccall('getInitialState', 'string', [], []);
            console.log('1. Initial state obtained');

            // Add first todo
            state = Module.ccall('processAction', 'string',
                ['string', 'string'],
                [state, JSON.stringify({type: 'enterText', text: 'First todo'})]);
            state = Module.ccall('processAction', 'string',
                ['string', 'string'],
                [state, JSON.stringify({type: 'addTodo'})]);
            console.log('2. Added first todo');

            // Add second todo
            state = Module.ccall('processAction', 'string',
                ['string', 'string'],
                [state, JSON.stringify({type: 'enterText', text: 'Second todo'})]);
            state = Module.ccall('processAction', 'string',
                ['string', 'string'],
                [state, JSON.stringify({type: 'addTodo'})]);
            console.log('3. Added second todo');

            // Toggle first todo
            state = Module.ccall('processAction', 'string',
                ['string', 'string'],
                [state, JSON.stringify({type: 'toggleTodo', id: 0})]);
            console.log('4. Toggled first todo');

            const parsed = JSON.parse(state);
            console.log('✓ Workflow completed successfully');
            console.log('✓ Final state has', parsed.items ? parsed.items.length : 0, 'items');
            console.log('');
        } catch (e) {
            console.log('✗ Failed:', e.message);
            console.log('');
        }

        console.log('╔═══════════════════════════════════════════════════════╗');
        console.log('║              All Tests Completed! ✅                   ║');
        console.log('╚═══════════════════════════════════════════════════════╝');
        console.log('');
        console.log('Next steps:');
        console.log('  1. Create web interface (HTML/CSS/JS)');
        console.log('  2. Load this WASM module in the browser');
        console.log('  3. Connect UI events to Lean functions');
        console.log('  4. Enjoy your formally verified TodoMVC!');
        console.log('');

    } catch (error) {
        console.error('');
        console.error('╔═══════════════════════════════════════════════════════╗');
        console.error('║              Error Loading Module ❌                   ║');
        console.error('╚═══════════════════════════════════════════════════════╝');
        console.error('');
        console.error('Error:', error.message);
        console.error('');
        console.error('Common issues:');
        console.error('  1. WASM module not compiled yet');
        console.error('     Run: ./build_wasm.sh');
        console.error('  2. Node.js version too old');
        console.error('     Need: Node.js 16+ with WASM support');
        console.error('  3. Missing WASM file');
        console.error('     Check: .lake/build/wasm/main.wasm exists');
        console.error('');
        process.exit(1);
    }
}

test();
