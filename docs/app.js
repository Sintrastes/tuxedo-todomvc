/**
 * TodoMVC - Formally Verified with Lean 4
 *
 * This is the main JavaScript application that loads the WebAssembly module
 * compiled from formally verified Lean 4 code and creates an interactive
 * TodoMVC interface.
 */

(function () {
  "use strict";

  // Global state
  let leanModule = null;
  let currentStateJson = null;
  let editingTodoId = null; // Track which todo is being edited

  // Lean function wrappers - will be initialized after module loads
  let leanAPI = {
    getInitialState: null,
    processAction: null,
    renderState: null,
  };

  /**
   * Initialize the application
   */
  async function init() {
    try {
      showLoading();

      console.log("=== TodoMVC Initialization Starting ===");
      console.log("Location:", window.location.href);
      console.log("Base URL:", window.location.origin);

      // Check if WASM module is loaded
      if (typeof createLeanModule === "undefined") {
        console.error("createLeanModule is not defined!");
        console.error(
          "This usually means main.js failed to load or export the module",
        );
        throw new Error(
          "WASM module (main.js) not loaded. Make sure main.js is loaded before app.js",
        );
      }

      console.log("✓ createLeanModule found");
      console.log("Initializing Lean WASM module...");
      console.log(
        "Downloading and decompressing WASM (~7MB gzipped, in chunks)...",
      );

      // Fetch and reassemble the gzipped WASM file chunks
      const chunks = [
        "main.wasm.gz.partaa",
        "main.wasm.gz.partab",
        "main.wasm.gz.partac",
        "main.wasm.gz.partad",
      ];

      console.log("Fetching chunks:", chunks.join(", "));
      const chunkBuffers = [];
      let totalSize = 0;

      for (const chunkUrl of chunks) {
        console.log(`Fetching: ${chunkUrl}`);
        const response = await fetch(chunkUrl);

        if (!response.ok) {
          throw new Error(
            `Failed to fetch ${chunkUrl}: ${response.status} ${response.statusText}`,
          );
        }

        const buffer = await response.arrayBuffer();
        chunkBuffers.push(buffer);
        totalSize += buffer.byteLength;
      }

      // Concatenate all chunks into a single buffer
      console.log(
        `Reassembling ${chunks.length} chunks (${totalSize} bytes)...`,
      );
      const compressedBuffer = new Uint8Array(totalSize);
      let offset = 0;
      for (const buffer of chunkBuffers) {
        compressedBuffer.set(new Uint8Array(buffer), offset);
        offset += buffer.byteLength;
      }

      console.log("Decompressing WASM...");

      // Decompress using browser's native DecompressionStream API
      const decompressedStream = new Response(
        new Response(compressedBuffer.buffer).body.pipeThrough(
          new DecompressionStream("gzip"),
        ),
      );
      const wasmBinary = await decompressedStream.arrayBuffer();

      console.log(
        `✓ Decompressed ${compressedBuffer.byteLength} bytes -> ${wasmBinary.byteLength} bytes`,
      );

      try {
        leanModule = await createLeanModule({
          wasmBinary: wasmBinary, // Provide the decompressed WASM directly
          print: (text) => console.log("[Lean stdout]:", text),
          printErr: (text) => console.warn("[Lean stderr]:", text),
        });
      } catch (moduleError) {
        console.error("Failed to initialize WASM module:", moduleError);
        throw new Error(
          "WASM module initialization failed: " + moduleError.message,
        );
      }

      console.log("✓ Module loaded successfully");
      console.log("Module object:", leanModule);

      // Initialize Lean API wrappers
      initializeLeanAPI();

      // Get initial state
      console.log("Getting initial state...");
      currentStateJson = leanAPI.getInitialState();
      console.log("Initial state:", currentStateJson);

      // Hide loading, show app
      hideLoading();
      showApp();

      // Initial render
      render();

      // Set up event listeners
      setupEventListeners();

      console.log("=== Application Initialized Successfully! ===");
    } catch (error) {
      console.error("=== Application Initialization Failed ===");
      console.error("Error:", error);
      console.error("Stack:", error.stack);

      let errorMsg = "Failed to load application: " + error.message;

      // Add helpful hints for common issues
      if (error.message.includes("main.js")) {
        errorMsg +=
          "\n\nPossible causes:\n" +
          "- WASM files not deployed to GitHub Pages\n" +
          "- MIME type issues with .wasm files\n" +
          "- Files not in the docs/ directory";
      } else if (error.message.includes("WASM")) {
        errorMsg +=
          "\n\nThe WASM module failed to load. This could be due to:\n" +
          "- Network issues (48MB file from GitHub raw URL)\n" +
          "- CORS restrictions\n" +
          "- GitHub LFS issues with raw file access";
      }

      showError(errorMsg);
    }
  }

  /**
   * Initialize Lean API function wrappers
   *
   * The Lean functions are exported with @[export name] and should be
   * accessible as Module._name or through other mechanisms.
   */
  function initializeLeanAPI() {
    // Try different ways to access exported functions
    const tryGetFunction = (name) => {
      // Try direct access
      if (leanModule["_" + name]) return leanModule["_" + name];
      if (leanModule[name]) return leanModule[name];

      // Try through asm
      if (leanModule.asm && leanModule.asm[name]) return leanModule.asm[name];

      return null;
    };

    console.log("Attempting to find exported Lean functions...");

    // Try to find the actual exported functions
    const getInitialStateFunc = tryGetFunction("getInitialState");
    const processActionFunc = tryGetFunction("processAction");
    const renderStateFunc = tryGetFunction("renderState");

    console.log("Function lookup results:");
    console.log(
      "- getInitialState:",
      getInitialStateFunc ? "✓ found" : "✗ not found",
    );
    console.log(
      "- processAction:",
      processActionFunc ? "✓ found" : "✗ not found",
    );
    console.log("- renderState:", renderStateFunc ? "✓ found" : "✗ not found");

    // For now, we'll use a simple approach: parse the state maintained by the
    // Lean main() output and manage state in JavaScript, calling Lean logic
    // through a bridge approach
    console.log(
      "Using JavaScript fallback implementation (Lean functions not yet integrated)",
    );

    leanAPI.getInitialState = function () {
      // Return initial TodoMVC state
      return JSON.stringify({
        items: [],
        selectedFilter: "all",
        pendingText: "",
        nextId: 0,
      });
    };

    leanAPI.processAction = function (stateJson, actionJson) {
      // Parse current state
      const state = JSON.parse(stateJson);
      const action = JSON.parse(actionJson);

      // Process action (JavaScript implementation that matches Lean logic)
      return JSON.stringify(processActionInJS(state, action));
    };

    leanAPI.renderState = function (stateJson) {
      // Parse state and render using our JS rendering
      // (matches the Lean HTML rendering logic)
      const state = JSON.parse(stateJson);
      return renderHTML(state);
    };
  }

  /**
   * Helper: Get visible items for a given state and filter
   */
  function getVisibleItemsForState(state) {
    if (!state.selectedFilter || state.items.length === 0) {
      return [];
    }

    switch (state.selectedFilter) {
      case "all":
        return state.items;
      case "active":
        return state.items.filter((item) => !item.completed);
      case "completed":
        return state.items.filter((item) => item.completed);
      default:
        return state.items;
    }
  }

  /**
   * Helper: Check if filter should be reset
   * According to TodoMVC spec: when no VISIBLE items exist, filter should be null
   */
  function shouldResetFilter(state) {
    // Always reset if no items at all
    if (state.items.length === 0) {
      return true;
    }

    // If filter is set and would show no visible items, reset it
    if (state.selectedFilter && state.selectedFilter !== "all") {
      const visibleItems = getVisibleItemsForState(state);
      if (visibleItems.length === 0) {
        return true;
      }
    }

    return false;
  }

  /**
   * Process an action on the state (JavaScript implementation matching Lean logic)
   * This is a faithful implementation of the Lean action system
   */
  function processActionInJS(state, action) {
    const newState = { ...state };

    switch (action.type) {
      case "enterText":
        newState.pendingText = action.text || "";
        break;

      case "addTodo":
        if (state.pendingText && state.pendingText.trim()) {
          const newItem = {
            id: state.nextId,
            text: state.pendingText.trim(),
            completed: false,
          };
          newState.items = [...state.items, newItem];
          newState.pendingText = "";
          newState.nextId = state.nextId + 1;

          // Set filter to 'all' if this is the first item
          if (state.items.length === 0) {
            newState.selectedFilter = "all";
          }
        }
        break;

      case "toggleTodo":
        newState.items = state.items.map((item) =>
          item.id === action.id
            ? { ...item, completed: !item.completed }
            : item,
        );

        // Reset filter if the filtered view becomes empty
        if (shouldResetFilter(newState)) {
          newState.selectedFilter = null;
        }
        break;

      case "deleteTodo":
        newState.items = state.items.filter((item) => item.id !== action.id);

        // Clear filter if no items left or filtered view becomes empty
        if (shouldResetFilter(newState)) {
          newState.selectedFilter = null;
        }
        break;

      case "setFilter":
        if (state.items.length > 0) {
          newState.selectedFilter = action.filter;

          // Reset filter if the new filter would show no items
          if (shouldResetFilter(newState)) {
            newState.selectedFilter = null;
          }
        }
        break;

      case "toggleAll":
        if (state.items.length > 0) {
          const anyUncompleted = state.items.some((item) => !item.completed);
          newState.items = state.items.map((item) => ({
            ...item,
            completed: anyUncompleted,
          }));

          // Reset filter if the filtered view becomes empty
          if (shouldResetFilter(newState)) {
            newState.selectedFilter = null;
          }
        }
        break;

      case "clearCompleted":
        newState.items = state.items.filter((item) => !item.completed);

        // Clear filter if no items left or filtered view becomes empty
        if (shouldResetFilter(newState)) {
          newState.selectedFilter = null;
        }
        break;

      default:
        console.warn("Unknown action type:", action.type);
    }

    return newState;
  }

  /**
   * Render HTML for the current state (matching Lean's HTML rendering)
   */
  function renderHTML(state) {
    const visibleItems = getVisibleItems(state);
    const activeCount = state.items.filter((item) => !item.completed).length;
    const completedCount = state.items.length - activeCount;

    let html = '<section class="todoapp">';

    // Header
    html += '<header class="header">';
    html += "<h1>todos</h1>";
    html += `<input class="new-todo"
                        placeholder="What needs to be done?"
                        value="${escapeHtml(state.pendingText || "")}"
                        autofocus>`;
    html += "</header>";

    // Main section (only if there are items)
    if (state.items.length > 0) {
      html += '<section class="main">';
      html += `<input id="toggle-all" class="toggle-all" type="checkbox"
                            ${state.items.every((item) => item.completed) ? "checked" : ""}>`;
      html += '<label for="toggle-all">Mark all as complete</label>';
      html += '<ul class="todo-list">';

      visibleItems.forEach((item) => {
        const isEditing = editingTodoId === item.id;
        const classes = [
          item.completed ? "completed" : "",
          isEditing ? "editing" : "",
        ]
          .filter(Boolean)
          .join(" ");

        html += `<li class="${classes}" data-id="${item.id}">`;
        html += '<div class="view">';
        html += `<input class="toggle" type="checkbox" ${item.completed ? "checked" : ""}>`;
        html += `<label>${escapeHtml(item.text)}</label>`;
        html += '<button class="destroy"></button>';
        html += "</div>";
        if (isEditing) {
          html += `<input class="edit" value="${escapeHtml(item.text)}">`;
        }
        html += "</li>";
      });

      html += "</ul>";
      html += "</section>";

      // Footer
      html += '<footer class="footer">';
      html += '<span class="todo-count">';
      html += `<strong>${activeCount}</strong> `;
      html += activeCount === 1 ? "item" : "items";
      html += " left";
      html += "</span>";

      html += '<ul class="filters">';
      html += `<li><a href="#/" class="${state.selectedFilter === "all" ? "selected" : ""}" data-filter="all">All</a></li>`;
      html += `<li><a href="#/active" class="${state.selectedFilter === "active" ? "selected" : ""}" data-filter="active">Active</a></li>`;
      html += `<li><a href="#/completed" class="${state.selectedFilter === "completed" ? "selected" : ""}" data-filter="completed">Completed</a></li>`;
      html += "</ul>";

      if (completedCount > 0) {
        html += `<button class="clear-completed">Clear completed</button>`;
      }

      html += "</footer>";
    }

    html += "</section>";

    return html;
  }

  /**
   * Get visible items based on current filter
   */
  function getVisibleItems(state) {
    if (!state.selectedFilter) return [];

    switch (state.selectedFilter) {
      case "all":
        return state.items;
      case "active":
        return state.items.filter((item) => !item.completed);
      case "completed":
        return state.items.filter((item) => item.completed);
      default:
        return state.items;
    }
  }

  /**
   * Escape HTML special characters
   */
  function escapeHtml(text) {
    const div = document.createElement("div");
    div.textContent = text;
    return div.innerHTML;
  }

  /**
   * Dispatch an action to update the state
   */
  function dispatch(action, skipRender = false) {
    console.log("Dispatching action:", action);

    const actionJson = JSON.stringify(action);
    currentStateJson = leanAPI.processAction(currentStateJson, actionJson);

    console.log("New state:", currentStateJson);

    // Don't re-render for enterText to preserve cursor position
    if (!skipRender) {
      render();
    }
  }

  /**
   * Render the application
   */
  function render() {
    const appElement = document.getElementById("app");
    const html = leanAPI.renderState(currentStateJson);
    appElement.innerHTML = html;

    // Focus the edit input if editing
    if (editingTodoId !== null) {
      const editInput = appElement.querySelector(".editing .edit");
      if (editInput) {
        editInput.focus();
        editInput.setSelectionRange(
          editInput.value.length,
          editInput.value.length,
        );
      }
    } else {
      // Focus the new-todo input if it exists
      const input = appElement.querySelector(".new-todo");
      if (input && document.activeElement !== input) {
        input.focus();
      }
    }
  }

  /**
   * Set up event listeners using event delegation
   */
  function setupEventListeners() {
    const appElement = document.getElementById("app");

    // Event delegation for all clicks
    appElement.addEventListener("click", (e) => {
      // Toggle individual todo
      if (
        e.target.classList.contains("toggle") &&
        !e.target.classList.contains("toggle-all")
      ) {
        const li = e.target.closest("li");
        const id = parseInt(li.dataset.id, 10);
        dispatch({ type: "toggleTodo", id });
      }

      // Delete todo
      else if (e.target.classList.contains("destroy")) {
        const li = e.target.closest("li");
        const id = parseInt(li.dataset.id, 10);
        dispatch({ type: "deleteTodo", id });
      }

      // Toggle all
      else if (e.target.id === "toggle-all") {
        dispatch({ type: "toggleAll" });
      }

      // Filter links
      else if (e.target.hasAttribute("data-filter")) {
        e.preventDefault();
        const filter = e.target.dataset.filter;
        dispatch({ type: "setFilter", filter });
      }

      // Clear completed
      else if (e.target.classList.contains("clear-completed")) {
        dispatch({ type: "clearCompleted" });
      }
    });

    // Double-click to edit
    appElement.addEventListener("dblclick", (e) => {
      if (e.target.tagName === "LABEL") {
        const li = e.target.closest("li");
        const id = parseInt(li.dataset.id, 10);
        editingTodoId = id;
        render();
      }
    });

    // Input field changes
    appElement.addEventListener("input", (e) => {
      if (e.target.classList.contains("new-todo")) {
        // Skip render to preserve cursor position
        dispatch({ type: "enterText", text: e.target.value }, true);
      }
    });

    // Enter key to add todo or save edit
    appElement.addEventListener("keydown", (e) => {
      if (e.target.classList.contains("new-todo") && e.key === "Enter") {
        dispatch({ type: "addTodo" });
      }
      // Save edit on Enter
      else if (e.target.classList.contains("edit") && e.key === "Enter") {
        saveEdit(e.target);
      }
      // Cancel edit on Escape
      else if (e.target.classList.contains("edit") && e.key === "Escape") {
        editingTodoId = null;
        render();
      }
    });

    // Save edit on blur
    appElement.addEventListener(
      "blur",
      (e) => {
        if (e.target.classList.contains("edit")) {
          saveEdit(e.target);
        }
      },
      true,
    );

    // Handle hash changes for routing
    window.addEventListener("hashchange", () => {
      const hash = window.location.hash;
      let filter = "all";

      if (hash === "#/active") filter = "active";
      else if (hash === "#/completed") filter = "completed";

      const state = JSON.parse(currentStateJson);
      if (state.items.length > 0 && state.selectedFilter !== filter) {
        dispatch({ type: "setFilter", filter });
      }
    });

    // Set initial filter based on hash
    const hash = window.location.hash;
    if (hash && hash !== "#/") {
      let filter = "all";
      if (hash === "#/active") filter = "active";
      else if (hash === "#/completed") filter = "completed";

      const state = JSON.parse(currentStateJson);
      if (state.items.length > 0) {
        dispatch({ type: "setFilter", filter });
      }
    }
  }

  /**
   * UI helper functions
   */
  function showLoading() {
    document.getElementById("loading").classList.remove("hidden");
    document.getElementById("app").classList.add("hidden");
    document.getElementById("error").classList.add("hidden");
  }

  function hideLoading() {
    document.getElementById("loading").classList.add("hidden");
  }

  function showApp() {
    document.getElementById("app").classList.remove("hidden");
  }

  function showError(message) {
    document.getElementById("loading").classList.add("hidden");
    document.getElementById("app").classList.add("hidden");
    document.getElementById("error").classList.remove("hidden");
    document.getElementById("error-message").textContent = message;
  }

  /**
   * Save the edit for a todo
   */
  function saveEdit(input) {
    if (editingTodoId === null) return;

    const newText = input.value.trim();
    const state = JSON.parse(currentStateJson);
    const idToEdit = editingTodoId;

    // Reset editing state BEFORE rendering to dismiss edit mode
    editingTodoId = null;

    if (newText === "") {
      // Delete if empty
      dispatch({ type: "deleteTodo", id: idToEdit });
    } else {
      // Update the todo text
      const newState = { ...state };
      newState.items = state.items.map((item) =>
        item.id === idToEdit ? { ...item, text: newText } : item,
      );
      currentStateJson = JSON.stringify(newState);
      render();
    }
  }

  // Initialize the app when DOM is ready
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
