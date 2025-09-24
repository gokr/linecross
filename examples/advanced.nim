## Advanced Linecross Example
##
## This example demonstrates advanced features including:
## - Custom history callbacks  
## - Colored prompts and text
## - Custom key bindings
## - History management

import ../linecross
import std/[strutils, tables, times, terminal]

# Custom history storage
var customHistory: seq[string] = @[]
var historyMetadata: Table[string, string] = initTable[string, string]()

proc customHistoryLoad(): seq[string] =
  ## Custom history loader
  result = customHistory
  echo "Loaded ", result.len, " entries from custom storage"

proc customHistorySave(entries: seq[string]): bool =
  ## Custom history saver  
  customHistory = entries
  let timestamp = $now()
  for entry in entries:
    historyMetadata[entry] = timestamp
  echo "Saved ", entries.len, " entries to custom storage"
  return true

proc advancedCompletionCallback(buffer: string, cursorPos: int, isSecondTab: bool): string =
  ## Advanced completion callback
  let commands = @[
    "history_test", "show_metadata", "search_history",
    "color_test", "key_info", "help", "exit"
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
      return matches[0][currentWord.len..^1]
    elif matches.len > 1:
      return ""
  else:
    # Second tab - show matches with descriptions
    var matches: seq[string] = @[]
    for cmd in commands:
      if cmd.startsWith(currentWord):
        matches.add(cmd)
    
    if matches.len > 0:
      echo "\nAdvanced commands:"
      for cmd in matches:
        let description = case cmd:
          of "history_test": "Add test entries to history"
          of "show_metadata": "Display history metadata" 
          of "search_history": "Search through history"
          of "color_test": "Test colored output"
          of "key_info": "Show custom key binding info"
          of "help": "Show detailed help"
          of "exit": "Exit the demo"
          else: "Command: " & cmd
        echo "  ", fgCyan, cmd, resetStyle, " - ", description
      echo ""
  
  return ""

proc showColorDemo() =
  echo "\nColor demonstration:"
  echo fgRed, "Red text", resetStyle
  echo fgGreen, "Green text", resetStyle  
  echo fgYellow, "Yellow text", resetStyle
  echo fgBlue, "Blue text", resetStyle
  echo fgMagenta, "Magenta text", resetStyle
  echo fgCyan, "Cyan text", resetStyle
  echo styleBright, "Bright text", resetStyle
  echo styleUnderscore, "Underlined text", resetStyle

proc showHistoryMetadata() =
  echo "\nHistory metadata:"
  if historyMetadata.len == 0:
    echo "No metadata available yet"
    return
  for entry, timestamp in historyMetadata:
    echo fgCyan, "Entry: ", resetStyle, entry
    echo fgYellow, "  Time: ", resetStyle, timestamp
    echo ""

proc main() =
  echo "Advanced Linecross Features Demo"
  echo "==============================="
  echo ""
  
  # Initialize with history
  initLinecross(enableHistory = true)
  
  # Set up custom history callbacks
  registerHistorySaveCallback(customHistorySave)
  registerHistoryLoadCallback(customHistoryLoad)
  
  # Pre-populate history
  customHistory = @[
    "echo hello world",
    "ls -la", 
    "git status",
    "nim c -r example.nim",
    "find . -name '*.nim'"
  ]
  
  # Set colored prompt
  setPromptColor(fgGreen, {styleBright})
  
  # Register custom key callback for Ctrl+T (show buffer info)
  registerCustomKeyCallback do (key: int, buffer: string) -> bool:
    if key == 20: # Ctrl+T (ASCII value 20)
      echo "\n", fgYellow, "Buffer Info:", resetStyle
      echo "Content: '", buffer, "'"
      echo "Length: ", buffer.len, " characters"
      if buffer.len > 0:
        echo "Last char: '", buffer[^1], "' (ASCII ", ord(buffer[^1]), ")"
      echo ""
      return true
    return false
  
  # Register completion
  registerCompletionCallback(advancedCompletionCallback)
  
  echo "Advanced features initialized:"
  echo "- Custom history storage and callbacks"  
  echo "- Colored prompt (bright green)"
  echo "- Custom key binding (Ctrl+T for buffer info)"
  echo "- Advanced completion with descriptions"
  echo ""
  echo "Available commands:"
  echo "- history_test: Add test entries"
  echo "- show_metadata: Show history metadata"
  echo "- search_history: Search through history" 
  echo "- color_test: Demonstrate colors"
  echo "- key_info: Show custom key info"
  echo "- help: Detailed help"
  echo "- exit: Quit"
  echo ""
  echo "Try:", fgCyan, " Up/Down arrows", resetStyle, " for history navigation"
  echo "Try:", fgCyan, " Ctrl+T", resetStyle, " to see buffer information"
  echo "Try:", fgCyan, " Tab completion", resetStyle, " on partial commands"
  echo ""
  
  while true:
    let line = readline("advanced> ")
    
    case line.strip():
    of "exit":
      break
    of "history_test":
      echo "Adding test entries to history..."
      addToHistory("test command alpha")
      addToHistory("test command beta")
      addToHistory("test command gamma") 
      echo fgGreen, "Test entries added! Use Up arrow to see them.", resetStyle
      
    of "show_metadata":
      showHistoryMetadata()
      
    of "search_history":
      let pattern = readline("Enter search pattern: ")
      let results = lookupHistory(pattern, 10)
      echo "\nSearch results for '", fgYellow, pattern, resetStyle, "':"
      for i, result in results:
        echo "  ", fgCyan, i + 1, ".", resetStyle, " ", result
      if results.len == 0:
        echo "No matches found"
        
    of "color_test":
      showColorDemo()
      
    of "key_info":
      echo "\nCustom Key Bindings:"
      echo fgCyan, "Ctrl+T:", resetStyle, " Show buffer information"
      echo "\nStandard shortcuts available:"
      echo "- Tab: Completion" 
      echo "- Ctrl-A/E: Start/end of line"
      echo "- Ctrl-K/U: Cut to end/start of line"
      echo "- Up/Down: History navigation"
      echo "- Ctrl-L: Clear screen"
      echo "- Ctrl-C: Exit"
      
    of "help":
      echo """
Advanced Features Help:

CUSTOM HISTORY:
- Uses custom storage with callbacks
- Tracks metadata like timestamps
- History is loaded/saved via custom functions
- Try 'search_history' to search entries

COLORED OUTPUT:
- Prompt uses bright green color
- Output can use terminal colors
- Standard ANSI color codes supported

CUSTOM KEYS:
- Ctrl+T shows buffer information
- Custom key callbacks can be registered
- Callbacks receive key code and current buffer

COMPLETION:
- Context-aware tab completion
- Shows command descriptions on double-tab
- Supports partial matching

HISTORY FEATURES:
- Up/Down arrows navigate history
- lookupHistory() for pattern searching
- Custom save/load callbacks
- Persistent across sessions
"""
    else:
      if line.len > 0:
        echo "Command executed: ", fgGreen, line, resetStyle
        echo "This demonstrates the advanced input capabilities."
  
  # Save history using custom callback
  echo "\nSaving history before exit..."
  echo fgGreen, "Advanced demo completed successfully!", resetStyle

when isMainModule:
  main()