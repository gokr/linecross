## Extended Features Example
##
## This example demonstrates linecross with extended features enabled,
## including word movement, text transformation, and advanced editing.

import ../linecross
import std/strutils

proc completionCallback(buffer: string, cursorPos: int, isSecondTab: bool): string =
  ## Simple completion for testing extended features
  let commands = @[
    "uppercase_demo", "lowercase_demo", "capitalize_demo",
    "word_navigation_demo", "cut_paste_demo", 
    "help", "features", "exit"
  ]
  
  # Find current word
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
      return matches[0][currentWord.len..^1]  # Complete the match
    elif matches.len > 1:
      return ""  # Wait for second tab
  else:
    # Second tab - show matches
    var matches: seq[string] = @[]
    for cmd in commands:
      if cmd.startsWith(currentWord):
        matches.add(cmd)
    
    if matches.len > 1:
      echo "\nAvailable completions:"
      for match in matches:
        echo "  ", match
      echo ""
  
  return ""

proc showFeatures() =
  echo "\nExtended Features Available:"
  echo "- Word Movement: Alt-B (back word), Alt-F (forward word)" 
  echo "- Text Transform: Alt-U (uppercase), Alt-L (lowercase), Alt-C (capitalize)"
  echo "- Cut/Paste: Ctrl-X (cut line), Ctrl-Y/V (paste)"
  echo "- Advanced Edit: Ctrl-T (transpose characters)"
  echo ""

proc main() =
  echo "Extended Linecross Features Example"
  echo "==================================="
  echo ""
  echo "This example demonstrates extended features based on the current API"
  echo "Note: Feature levels are not yet implemented, using standard initialization"
  echo ""
  
  # Initialize with history enabled
  initLinecross(enableHistory = true)
  
  # Register completion callback
  registerCompletionCallback(completionCallback)
  
  # Load history
  discard loadHistory("extended_history.txt")
  
  showFeatures()
  
  echo "Available test commands:"
  echo "- uppercase_demo: Test text transformation to UPPERCASE"
  echo "- lowercase_demo: Test text transformation to lowercase"
  echo "- capitalize_demo: Test text Capitalization"
  echo "- word_navigation_demo: Test word movement"
  echo "- cut_paste_demo: Test cut and paste"
  echo "- features: Show feature list again"
  echo "- help: Show detailed help"
  echo "- exit: Quit"
  echo ""
  
  while true:
    let line = readline("extended> ")
    
    case line.strip():
    of "exit":
      break
    of "features":
      showFeatures()
    of "help":
      echo """
Extended Features Help:

Standard shortcuts available:
- Tab: Autocomplete
- Ctrl-L: Clear screen
- Ctrl-A/E: Start/end of line  
- Ctrl-K/U: Cut to end/start of line
- Up/Down: History navigation
- Ctrl-C: Exit
- Backspace/Delete: Character editing
- Arrow keys: Cursor movement

History:
- Up/Down arrows navigate history
- History is saved/loaded automatically
- Use lookupHistory() for programmatic access

Completion:
- Tab completes if unique match
- Tab-Tab shows all matches
- Completion is context-aware
"""
    of "uppercase_demo":
      echo "Feature demo: Type text and use word movement and editing features"
      echo "Note: Advanced text transformation features are not yet implemented"
    of "lowercase_demo": 
      echo "Feature demo: Type text and use basic editing capabilities"
      echo "Note: Advanced text transformation features are not yet implemented"
    of "capitalize_demo":
      echo "Feature demo: Use basic readline functionality"
      echo "Note: Advanced text transformation features are not yet implemented"
    of "word_navigation_demo":
      echo "Feature demo: Use arrow keys and basic cursor movement"
      echo "Note: Advanced word movement features are not yet implemented"
    of "cut_paste_demo":
      echo "Use Ctrl-K to cut to end of line, then type and paste"
      echo "Note: Advanced cut/paste features are not yet implemented"
    else:
      if line.len > 0:
        echo "You entered: '", line, "'"
        echo "Try the demo commands or type 'help' for more info"
  
  # Save history on exit
  discard saveHistory("extended_history.txt")
  echo "Extended features example completed!"

when isMainModule:
  main()