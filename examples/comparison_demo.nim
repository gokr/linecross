## Comparison Demo - Before vs After Enhancement
##
## This demo shows the difference between normal mode (old behavior)
## and persistent mode (new enhancement) side by side.

import std/strutils
import "../linecross"

proc createSampleTable(): string =
  """┌────┬──────────────────┬─────────┐
│ ID │ Title            │ Status  │
├────┼──────────────────┼─────────┤
│ 1  │ Important Task   │ Active  │
│ 2  │ Bug Fix #123     │ Done    │
│ 3  │ Code Review      │ Pending │
│ 4  │ Documentation    │ Active  │
└────┴──────────────────┴─────────┘"""

proc demoNormalMode() =
  echo "=== BEFORE: Normal Mode (Old Behavior) ==="
  echo "This shows the old behavior where tables disrupt cursor positioning."
  echo "Notice how after displaying a table, input behavior may be affected."
  echo ""
  echo "Press Enter to start normal mode demo..."
  discard stdin.readLine()
  
  initLinecross()
  
  echo "Type 'table' to see the problem, 'quit' to continue to enhanced demo:"
  
  while true:
    let input = readline("normal> ")
    
    case input.strip().toLowerAscii():
    of "table":
      # In normal mode, this would disrupt cursor positioning
      echo "\nDisplaying table (this disrupts cursor):"
      echo createSampleTable()
      echo "\n↑ Notice: cursor positioning may be disrupted after table display"
    of "quit", "next":
      break
    else:
      echo "You typed: " & input
  
  echo "\nNormal mode demo completed."
  echo "You may have noticed cursor positioning issues after the table."

proc demoEnhancedMode() =
  echo "\n=== AFTER: Enhanced Mode (New Behavior) ==="
  echo "This shows the new persistent input area that solves the cursor issue."
  echo "Tables and other output appear above while input stays clean at bottom."
  echo ""
  echo "Press Enter to start enhanced mode demo..."
  discard stdin.readLine()
  
  initLinecross()
  
  # Enter the enhanced persistent mode
  enterPersistentMode()
  
  printAboveInput("""Enhanced mode active! 
  
Try the same commands:
• 'table' - Display table above (no cursor disruption!)
• 'multiple' - Show multiple outputs
• 'quit' - Exit demo

Notice how the input area stays perfectly positioned at the bottom.""")
  
  while true:
    let input = readline("enhanced> ")
    
    case input.strip().toLowerAscii():
    of "table":
      # In enhanced mode, this displays above without disrupting input
      printAboveInput("Table displayed above input (cursor stays clean!):\n" & createSampleTable())
    of "multiple":
      printAboveInput("First output: Some command results")
      printAboveInput("Second output: More results\n" & createSampleTable() & "\nThird: Even more content!")
    of "quit", "exit":
      break
    else:
      printAboveInput("Command executed: " & input)
  
  exitPersistentMode()
  echo "\nEnhanced mode demo completed."

proc showComparison() =
  echo "\n=== COMPARISON SUMMARY ==="
  echo ""
  echo "BEFORE (Normal Mode):"
  echo "❌ Tables disrupt cursor positioning"
  echo "❌ Output mixes with input prompt"  
  echo "❌ Scrolling can lose input context"
  echo "❌ Completion display interferes with input"
  echo ""
  echo "AFTER (Enhanced Mode):"
  echo "✅ Persistent input area at bottom"
  echo "✅ All output appears above input"
  echo "✅ Cursor always properly positioned"
  echo "✅ Input context never lost"
  echo "✅ Automatic paging for long output"
  echo "✅ Temporary completions below input"
  echo ""
  echo "This enhancement solves the Nancy table cursor issue and provides"
  echo "a foundation for sophisticated terminal interfaces like modern IDEs."

proc main() =
  echo "Enhanced Linecross - Before vs After Comparison"
  echo "==============================================="
  echo ""
  echo "This demo shows the difference between the old behavior that had"
  echo "cursor positioning issues with tables, and the new enhanced mode"
  echo "that provides a persistent input area."
  echo ""
  
  # Show normal mode first
  demoNormalMode()
  
  # Show enhanced mode  
  demoEnhancedMode()
  
  # Summary
  showComparison()

when isMainModule:
  main()