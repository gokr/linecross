import linecross
import std/[strutils, terminal]

# Simple completion function for testing
proc myCompletion(buffer: string, cursorPos: int, isSecondTab: bool): string =
  # Define some test commands
  let commands = @["help", "history", "hello", "world", "exit", "test"]
  
  # Extract the current word at cursor position
  var wordStart = cursorPos
  while wordStart > 0 and buffer[wordStart - 1] notin [' ', '\t']:
    dec wordStart
  
  let currentWord = if wordStart < cursorPos: buffer[wordStart..<cursorPos] else: ""
  
  if not isSecondTab:
    # First tab - try to complete
    var matches: seq[string] = @[]
    for cmd in commands:
      if cmd.startsWith(currentWord):
        matches.add(cmd)
    
    if matches.len == 1:
      # Single match - return the completion
      return matches[0][currentWord.len..^1]
    elif matches.len > 1:
      # Multiple matches - store for second tab, no completion yet
      echo ""  # Go to new line to show we're waiting for second tab
      return ""
  else:
    # Second tab - show all matches
    var matches: seq[string] = @[]
    for cmd in commands:
      if cmd.startsWith(currentWord):
        matches.add(cmd)
    
    if matches.len > 1:
      echo "\nAvailable completions:"
      for match in matches:
        echo "  ", match
      echo ""  # Add blank line
      
    return ""  # Don't insert anything on second tab
  
  return ""

proc main() =
  # Initialize linecross with history
  initLinecross(enableHistory = true)
  
  # Set colored prompt
  setPromptColor(fgCyan, {styleBright})
  
  # Register our completion callback
  registerCompletionCallback(myCompletion)
  
  echo "Linecross2 Completion Test"
  echo "Available commands: help, history, hello, world, exit, test"
  echo "Try typing partial commands and press Tab to complete"
  echo "Press Tab twice to see all possible completions"
  echo ""
  
  while true:
    let input = readline("test> ")
    
    if input == "exit":
      break
    elif input == "help":
      echo "Available commands: help, history, hello, world, exit, test"
    elif input == "history":
      echo "History feature enabled - use Up/Down arrows"
    elif input.startsWith("hello"):
      echo "Hello to you too!"
    elif input.startsWith("world"):
      echo "What a wonderful world!"
    elif input.startsWith("test"):
      echo "Testing completion system..."
    elif input.len > 0:
      echo "Unknown command: ", input
      echo "Type 'help' for available commands"
  
  echo "Goodbye!"

when isMainModule:
  main()