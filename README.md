
# Tuxedo TodoMVC

A implementation of TodoMVC in Lean 4 and JavaScript with a vibe-coded implementation and formally verified proof that the implementation meets the specification.

<div align="center">
  <img width="726" height="632" alt="Screenshot 2026-01-10 at 9 49 53 PM" src="https://github.com/user-attachments/assets/0acc34c5-66f2-48df-9af5-c31b91d49d2c" />
</div>

# How it works

The [spec](https://github.com/Sintrastes/tuxedo-todomvc/blob/main/TuxedoMVC/TodoMVC/Spec.lean) was based on [this specification](https://gist.github.com/owickstrom/1a0698ef6a47df07dfc1fe59eda12983), translated to Linear Temporal Logic, and the [implementation](https://github.com/Sintrastes/tuxedo-todomvc/blob/main/TuxedoMVC/TodoMVC/App.lean) was vibe-coded with Claude models with the [Zed](https://zed.dev/) IDE's agentic mode in an evening. The [formal proof](https://github.com/Sintrastes/tuxedo-todomvc/blob/main/TuxedoMVC/TodoMVC/Proofs.lean) that the application implements the spec was also vibe-coded, but is gaurnteed to be correct (provided you trust the Lean 4 theorem prover)!

The gratuitious markdown output (and .js test driver scripts it used) from the agent is kept in `slop` for posterity. Some of it is probably useful, but there's also a lot of noise. 

The formally verified portion is the reducer (describing how the state of the application updates over time in response to events), NOT the Javascript binding code. The Javascript code likely has some bugs, as this has not yet been properly integration tested against the original quickstrom spec (pull requests welcome!).

# Try it out locally!

First, install [emscripten](https://emscripten.org/docs/getting_started/downloads.html) and [Lean 4](https://lean-lang.org/install/). Then:

```
lake build WebMain
lake exe lean2wasm
```

Finally, to try out the whole applicaiton locally, you can run:

```
./serve_web.sh
```

# Why "Tuxedo"?

Because they give off formal vibes.
