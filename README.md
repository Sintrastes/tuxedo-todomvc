
# Tuxedo TodoMVC

A implementation of TodoMVC in Lean 4 and JavaScript with a vibe-coded implementation and formally verified proof that the implementation meets the specification.

The spec (Spec.lean) was based on [this specification](https://gist.github.com/owickstrom/1a0698ef6a47df07dfc1fe59eda12983), translated to Linear Temporal Logic, and the implementation was vibe-coded with Claude models with the [Zed](https://zed.dev/) IDE's agentic mode in an evening. 

The gratuitious markdown output (and .js test driver scripts it used) from the agent is kept in `slop` for posterity.

The formally verified portion is the reducer (describing how the state of the application updates over time in response to events), NOT the Javascript binding code. 

# Try it out locally!

First, install emscripten and Lean 4. Then:

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
