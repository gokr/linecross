## Simple example demonstrating Crossline usage
## Port of the original example.c

import linecross, strformat, strutils

proc completionHook(buf: string, completions: var Completions) =
  ## Completion callback that provides SQL-like commands
  let commands = @[
    "insert", "select", "update", "delete", "create", "drop", 
    "show", "describe", "help", "exit", "history"
  ]
  
  for cmd in commands:
    if cmd.startsWith(buf.toLowerAscii()):
      addCompletion(completions, cmd)

proc main() =
  echo "Crossline for Nim - Example"
  echo "Type 'exit' to quit"
  echo ""
  
  # Set up completion
  registerCompletionCallback(completionHook)
  
  # Load history
  discard loadHistory("history.txt")
  
  # Main loop
  while true:
    try:
      let line = readline("Crossline> ")
      
      if line == "":
        echo "Goodbye!"
        break
      
      if line == "exit":
        echo "Goodbye!"
        break
      elif line == "clear":
        clearHistory()
        echo "History cleared."
      elif line == "history":
        echo "History:"
        # TODO: Add a public function to get history entries
        echo "History display not implemented yet."
      else:
        echo &"Read line: \"{line}\""
    
    except EOFError:
      echo "\nGoodbye!"
      break
  
  # Save history
  discard saveHistory("history.txt")

when isMainModule:
  main()