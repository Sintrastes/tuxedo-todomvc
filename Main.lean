/-
  Main entry point for the TodoMVC application

  This runs the CLI driver for interacting with the formally verified
  TodoMVC implementation.
-/

import LtlFormalVerification

def main (args : List String) : IO Unit := do
  match args with
  | ["--interactive"] | ["-i"] =>
      -- Start interactive step-by-step REPL
      TodoMVC.Driver.mainStepByStep

  | ["--help"] | ["-h"] =>
      IO.println "TodoMVC - Formally Verified Edition"
      IO.println ""
      IO.println "Usage: ltl_formal_verification [option]"
      IO.println ""
      IO.println "Options:"
      IO.println "  (no args)        Start interactive REPL"
      IO.println "  --interactive, -i Start interactive step-by-step mode"
      IO.println "  --help, -h       Show this help message"

  | [] =>
      -- Start interactive REPL
      TodoMVC.Driver.main

  | _ =>
      IO.println "Unknown arguments. Use --help for usage information."
