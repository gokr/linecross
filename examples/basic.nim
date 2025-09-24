## Basic Linecross Example
## 
## This example demonstrates the most basic usage of linecross:
## - Simple readline functionality
## - Basic editing with arrow keys, backspace, etc.
## - Enter to submit, Ctrl+C to exit

import ../linecross

proc main() =
  # Initialize linecross with basic features
  initLinecross()
  
  echo "Basic Linecross Example"
  echo "======================"
  echo ""
  echo "Features demonstrated:"
  echo "- Basic text input and editing"
  echo "- Arrow key navigation"
  echo "- Backspace/Delete"
  echo "- Enter to submit, Ctrl+C to exit"
  echo ""
  echo "Type some text and press Enter (empty line to exit):"
  echo ""
  
  while true:
    let input = readline("basic> ")
    if input.len == 0:
      echo "Goodbye!"
      break
    echo "You entered: ", input

when isMainModule:
  main()