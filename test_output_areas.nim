## Test example for the new output areas functionality
import linecross
import strutils

proc main() =
  # Initialize linecross with history
  initLinecross(enableHistory = true)
  
  echo "Testing new output areas functionality!"
  echo "Commands:"
  echo "  status - set status area"
  echo "  info - set info area"
  echo "  clear - clear both areas" 
  echo "  output - write scrolling output"
  echo "  redraw - force redraw"
  echo "  quit - exit"
  echo ""
  
  while true:
    let input = readline("> ")
    
    if input == "quit":
      break
    elif input == "status":
      setStatus(@["Status: Connected", "Branch: main", "Files: 3 modified"])
      redraw()
    elif input == "info":
      setInfo(@["Available completions:", "  file.nim", "  folder/", "  readme.md"])
      redraw()
    elif input == "clear":
      clearStatus()
      clearInfo()
      redraw()
    elif input == "output":
      writeOutput("This is scrolling output that appears above the input area!")
    elif input == "redraw":
      redraw()
    elif input.startsWith("say "):
      let message = input[4..^1]
      writeOutput("You said: " & message)
    else:
      if input.len > 0:
        writeOutput("Unknown command: " & input)

when isMainModule:
  main()