## Example demonstrating Tab completion in linecross
## 
## This shows both single-tab completion (for unique matches) 
## and double-tab behavior (to list all possible matches)

import ../linecross
import std/strutils

proc fileCompletion(buffer: string, cursorPos: int, isSecondTab: bool): string =
  ## Example completion for file operations
  let commands = @[
    "open", "save", "close", "list", "create", "delete",
    "copy", "move", "rename", "search", "help", "exit"
  ]
  
  # Find the current word being completed
  var wordStart = cursorPos
  while wordStart > 0 and buffer[wordStart - 1] notin [' ', '\t']:
    dec wordStart
  
  let currentWord = if wordStart < cursorPos: buffer[wordStart..<cursorPos] else: ""
  
  # Find matches
  var matches: seq[string] = @[]
  for cmd in commands:
    if cmd.startsWith(currentWord):
      matches.add(cmd)
  
  if not isSecondTab:
    # First tab press
    case matches.len:
    of 0:
      return ""  # No matches
    of 1:
      # Single match - complete it
      return matches[0][currentWord.len..^1]
    else:
      # Multiple matches - wait for second tab
      return ""
  else:
    # Second tab press - show all matches
    if matches.len > 1:
      echo "\nPossible completions:"
      for i, match in matches:
        if (i + 1) mod 4 == 0:
          echo "  ", match  # New line every 4 items
        else:
          stdout.write("  ", match, "    ")
      if matches.len mod 4 != 0:
        echo ""  # Final newline if needed
      echo ""
    
    return ""  # Don't insert anything

proc main() =
  echo "File Manager Completion Demo"
  echo "Commands: open, save, close, list, create, delete, copy, move, rename, search, help, exit"
  echo ""
  echo "Usage:"
  echo "- Type partial command + Tab to complete (if unique)"
  echo "- Type partial command + Tab + Tab to see all matches"
  echo "- Try: 'o<Tab>' vs 's<Tab><Tab>'"
  echo ""

  initLinecross(enableHistory = true)
  registerCompletionCallback(fileCompletion)
  
  while true:
    let input = readline("file> ")
    
    case input:
    of "exit", "quit":
      break
    of "help":
      echo "Available commands:"
      echo "  open <file>   - Open a file"
      echo "  save [file]   - Save current file"
      echo "  list          - List files" 
      echo "  create <file> - Create new file"
      echo "  delete <file> - Delete file"
      echo "  copy <src> <dst> - Copy file"
      echo "  move <src> <dst> - Move file"
      echo "  rename <old> <new> - Rename file"
      echo "  search <term> - Search in files"
    of "list":
      echo "Files: document.txt, readme.md, config.json"
    else:
      if input.len > 0:
        let parts = input.split(' ')
        if parts.len > 0:
          echo "Executing: ", parts[0]
          if parts.len > 1:
            echo "With arguments: ", parts[1..^1].join(" ")
        else:
          echo "Unknown command: ", input

when isMainModule:
  main()