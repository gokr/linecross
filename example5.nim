## Extended Features Example for Linecross
## 
## This example demonstrates the new configurable extended shortcut features
## including word movement, text transformation, and advanced cut/paste operations

import linecross
import std/strutils

proc completionHook(buf: string, completions: var Completions) =
  ## Example completion with commands demonstrating text transformation
  let commands = @[
    "uppercase_test", "lowercase_test", "capitalize_test",
    "word_navigation", "cut_paste_demo", 
    "help", "exit", "features"
  ]
  
  for cmd in commands:
    if cmd.startsWith(buf.split(' ')[^1]):
      addCompletion(completions, cmd, "Demo command for " & cmd)

proc showFeatureStatus() =
  echo "\nCurrent Extended Features Status:"
  let features = getExtendedFeatures()
  echo "- Word Movement (Alt-B/F): ", features.wordMovement
  echo "- Text Transform (Alt-U/L/C): ", features.textTransform  
  echo "- Advanced Cut/Paste (Ctrl-X/Y/V): ", features.advancedCutPaste
  echo "- Multi-line Navigation: ", features.multilineNav
  echo "- History Search: ", features.historySearch
  echo "- Help System: ", features.helpSystem
  echo "- Advanced Editing (Ctrl-T): ", features.advancedEdit
  when defined(useSystemClipboard):
    echo "- System Clipboard Integration: ENABLED"
  else:
    echo "- System Clipboard Integration: DISABLED (compile with -d:useSystemClipboard to enable)"

proc main() =
  echo "Linecross Extended Features Demo"
  echo "================================"
  echo ""
  echo "Available configurations:"
  echo "1. basic     - Current basic implementation (15 shortcuts)"
  echo "2. essential - Word movement + cut/paste (25 shortcuts)"  
  echo "3. standard  - Essential + text transform + multiline (40 shortcuts)"
  echo "4. full      - All extended features (65+ shortcuts)"
  echo ""
  
  # Get user preference for feature set
  let choice = readline("Choose feature set (1-4, or press Enter for standard): ")
  
  case choice:
  of "1", "basic":
    initLinecross(BasicFeatures)
    echo "Using BasicFeatures (15 shortcuts)"
  of "2", "essential":
    initLinecross(EssentialFeatures)
    echo "Using EssentialFeatures (25 shortcuts)"
  of "3", "standard", "":
    initLinecross(StandardFeatures)  
    echo "Using StandardFeatures (40 shortcuts)"
  of "4", "full":
    initLinecross(FullFeatures)
    echo "Using FullFeatures (65+ shortcuts)"
  else:
    initLinecross(StandardFeatures)
    echo "Invalid choice, using StandardFeatures"
  
  # Register completion
  registerCompletionCallback(completionHook)
  
  # Load history
  discard loadHistory("extended_demo_history.txt")
  
  echo ""
  echo "Extended Shortcuts Available (depending on your selection):"
  echo "- Word Movement: Alt-B (back word), Alt-F (forward word)"
  echo "- Text Transform: Alt-U (uppercase), Alt-L (lowercase), Alt-C (capitalize)"
  echo "- Cut/Paste: Ctrl-X (cut line), Ctrl-Y/V (paste), Ctrl-W (cut to space)"
  echo "- Advanced Edit: Ctrl-T (transpose characters)"
  echo ""
  echo "Type 'features' to see current configuration"
  echo "Type 'help' for usage tips, 'exit' to quit"
  echo ""
  
  # Main readline loop
  while true:
    let line = readline("Extended> ")
    
    if line == "exit":
      break
    elif line == "features":
      showFeatureStatus()
    elif line == "help":
      echo """
Usage Tips for Extended Features:

Word Movement (if enabled):
- Alt-B: Move cursor back one word
- Alt-F: Move cursor forward one word  

Text Transformation (if enabled):
- Alt-U: Make current/following word UPPERCASE
- Alt-L: make current/following word lowercase  
- Alt-C: Capitalize Current/Following Word

Advanced Cut/Paste (if enabled):
- Ctrl-X: Cut entire line to clipboard
- Ctrl-Y or Ctrl-V: Paste from clipboard
- Ctrl-W: Cut from cursor back to last space

Advanced Editing (if enabled):  
- Ctrl-T: Transpose (swap) current and previous characters

Standard shortcuts work in all modes:
- Tab: Autocomplete, Ctrl-L: Clear screen
- Ctrl-A/E: Start/end of line, Ctrl-K/U: Cut to end/start
- Up/Down: History, Ctrl-C: Exit
"""
    elif line.startsWith("uppercase_test"):
      echo "Try: 'this is a test' then use Alt-U to uppercase words"
    elif line.startsWith("lowercase_test"):
      echo "Try: 'THIS IS A TEST' then use Alt-L to lowercase words"
    elif line.startsWith("capitalize_test"):  
      echo "Try: 'hello world' then use Alt-C to capitalize words"
    elif line.startsWith("word_navigation"):
      echo "Type a sentence and use Alt-B/F to navigate by words"
    elif line.startsWith("cut_paste_demo"):
      echo "Type text, use Ctrl-X to cut line, then Ctrl-Y to paste"
    else:
      echo "You entered: '", line, "'"
  
  # Save history
  discard saveHistory("extended_demo_history.txt")
  echo "Extended features demo completed!"

when isMainModule:
  main()