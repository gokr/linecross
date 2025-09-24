import linecross
import std/terminal

# Test basic functionality with history enabled
proc main() =
  # Initialize with history enabled
  initLinecross(enableHistory = true)
  
  # Set a colored prompt
  setPromptColor(fgGreen, {styleBright})
  
  # Register a custom key callback for testing (Ctrl+T to show buffer info)
  registerCustomKeyCallback do (key: int, buffer: string) -> bool:
    if key == 20: # Ctrl+T
      echo "\nBuffer: '", buffer, "', Length: ", buffer.len
      return true
    return false
  
  # Load existing history if available
  discard loadHistory("test_history.txt")
  
  echo "Enhanced Linecross2 Test"
  echo "Features:"
  echo "- History enabled (Up/Down arrows)"
  echo "- Colored prompt (green)"
  echo "- Word movement (Alt+B/F, Ctrl+Left/Right)"
  echo "- Clipboard operations:"
  echo "  * Ctrl+K: Cut to end of line"
  echo "  * Ctrl+U: Cut to beginning of line"
  echo "  * Ctrl+Y/V: Paste from clipboard"
  echo "  * Insert: Paste from clipboard"
  echo "- Custom key: Ctrl+T shows buffer info"
  echo "- History saved to test_history.txt"
  echo "- Type 'quit' to exit"
  echo ""
  
  while true:
    let input = readline("enhanced> ")
    
    if input == "quit":
      break
    elif input == "clear":
      clearHistory()
      echo "History cleared"
    elif input == "save":
      if saveHistory("test_history.txt"):
        echo "History saved"
      else:
        echo "Failed to save history"
    elif input.len > 0:
      echo "You entered: ", input
  
  # Save history on exit
  discard saveHistory("test_history.txt")
  echo "Goodbye!"

when isMainModule:
  main()