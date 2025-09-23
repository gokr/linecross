## Simple Demo - Basic Persistent Input Area Usage
##
## This is a minimal example showing how to use the enhanced linecross
## persistent input area functionality.

import std/strutils
import "../linecross"

proc main() =
  echo "Simple Persistent Input Area Demo"
  echo "================================="
  echo ""
  echo "This demo shows basic usage of the enhanced linecross."
  echo "The input prompt will stay at the bottom while output appears above."
  echo ""
  
  # Initialize linecross
  initLinecross()
  setPrompt("simple> ")
  
  # Enter persistent mode - this creates the fixed input area
  enterPersistentMode()
  
  echo "Entered persistent mode. Try these commands:"
  echo "• 'hello' - Simple greeting"
  echo "• 'table' - Display a sample table"  
  echo "• 'long' - Show long content with paging"
  echo "• 'completion' - Show completion example below input"
  echo "• 'clear' - Clear the output area"
  echo "• 'quit' - Exit the demo"
  echo ""
  
  while true:
    # Read input - this will maintain the persistent input area
    let input = readline("simple> ")
    
    case input.strip().toLowerAscii():
    of "hello":
      # Display simple content above input
      printAboveInput("Hello! This text appears above your input area.")
      
    of "table":
      # Display a table above input (simulating Nancy table issue)
      let table = """┌─────┬───────────┬────────┐
│ ID  │ Name      │ Status │
├─────┼───────────┼────────┤
│ 1   │ Alice     │ Active │
│ 2   │ Bob       │ Away   │
│ 3   │ Charlie   │ Active │
└─────┴───────────┴────────┘"""
      printAboveInput("Sample table:\n" & table)
      
    of "long":
      # Test paging functionality
      var longContent = "This is long content that tests paging:\n\n"
      for i in 1..30:
        longContent.add "Line " & $i & ": Some content that demonstrates scrolling\n"
      printAboveInput(longContent)
      
    of "completion":
      # Show temporary completion below input
      printBelow("""Available commands:
  hello  - Show greeting
  table  - Display table
  long   - Long content  
  clear  - Clear output
  quit   - Exit demo""")
      
    of "clear":
      # Clear output area
      printAboveInput("")
      clearBelow()
      
    of "quit", "exit":
      break
      
    elif input.strip().len > 0:
      # Echo any other input
      printAboveInput("You entered: " & input)
      clearBelow()  # Clear any temporary completions
    else:
      # Clear temporary displays on empty input
      clearBelow()
  
  # Exit persistent mode and return to normal
  exitPersistentMode()
  
  echo ""
  echo "Demo completed. Normal terminal behavior restored."

when isMainModule:
  main()