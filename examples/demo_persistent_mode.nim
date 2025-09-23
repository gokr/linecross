## Demo of Enhanced Linecross Persistent Input Area
##
## This example demonstrates the new persistent input area functionality
## that solves cursor positioning issues with table output and provides
## a foundation for better completion display.

import std/[strutils, strformat, times, os]
import "../linecross"

proc createSampleTable(): string =
  ## Create a sample table similar to Niffler's conversation list
  result = """┌────┬──────────────────────┬─────────────────┬──────────┬─────────┬──────────────┐
│ ID │ Title                │ Mode/Model      │ Messages │ Status  │ Activity     │
├────┼──────────────────────┼─────────────────┼──────────┼─────────┼──────────────┤
│ 23 │ Test                 │ Code/test-model │ 0 msgs   │ Active  │ Sep 11 15:12 │
│ 22 │ Fix model startup    │ Plan/gpt4       │ 31 msgs  │ Current │ Sep 11 15:12 │
│ 21 │ Test                 │ Code/synthetic  │ 2 msgs   │ Active  │ Sep 11 15:12 │
│ 20 │ parser-error         │ Code/synthetic  │ 104 msgs │ Active  │ Sep 11 15:12 │
│ 19 │ riddle              │ Plan/synthetic  │ 49 msgs  │ Active  │ Sep 11 15:12 │
│ 18 │ Test                │ Code/synthetic  │ 0 msgs   │ Active  │ Sep 11 15:12 │
└────┴──────────────────────┴─────────────────┴──────────┴─────────┴──────────────┘"""

proc createLongContent(): string =
  ## Create content that will require paging
  result = "Long output that exceeds terminal height:\n"
  for i in 1..50:
    result.add &"Line {i}: This is a long line of text that demonstrates paging functionality\n"

proc createCompletionExample(): string =
  ## Create a completion list example
  result = """Available commands:
  /new [title]     - Create new conversation
  /list           - List all conversations  
  /archive <id>   - Archive conversation
  /switch <id>    - Switch to conversation
  /delete <id>    - Delete conversation
  /help           - Show this help"""

proc demoBasicPersistentMode() =
  ## Demo 1: Basic persistent mode with table display
  echo "=== Demo 1: Basic Persistent Input Area ==="
  echo "This shows how tables can be displayed above a persistent input area"
  echo "Press Enter to continue..."
  discard stdin.readLine()
  
  # Initialize linecross
  initLinecross()
  
  # Enter persistent mode
  enterPersistentMode()
  
  echo "\nEntered persistent mode. The input area is now at the bottom."
  echo "Type 'table' to see a sample table, 'help' for commands, or 'quit' to exit."
  
  while true:
    let input = readline("demo> ")
    
    case input.strip().toLowerAscii():
    of "table":
      let tableContent = createSampleTable()
      printAboveInput("Sample conversation table:\n" & tableContent)
    of "help":
      let helpContent = """Commands in persistent mode:
  table  - Display sample table above input
  below  - Show completion example below input  
  clear  - Clear content above input
  quit   - Exit demo"""
      printAboveInput(helpContent)
    of "below":
      let completions = createCompletionExample()
      printBelow(completions)
    of "clear":
      printAboveInput("")  # Clear by printing empty content
    of "quit", "exit":
      break
    else:
      printAboveInput(&"You typed: {input}")
  
  # Exit persistent mode
  exitPersistentMode()
  echo "\nExited persistent mode. Back to normal operation."

proc demoPagingFunctionality() =
  ## Demo 2: Content overflow and paging
  echo "\n=== Demo 2: Paging with Long Content ==="
  echo "This demonstrates automatic paging when content exceeds screen height"
  echo "Press Enter to continue..."
  discard stdin.readLine()
  
  initLinecross()
  enterPersistentMode()
  
  echo "\nType 'long' to see paging in action, or 'quit' to exit."
  
  while true:
    let input = readline("paging> ")
    
    case input.strip().toLowerAscii():
    of "long":
      let longContent = createLongContent()
      printAboveInput(longContent)
    of "short":
      printAboveInput("This is short content that fits easily.")
    of "quit", "exit":
      break
    else:
      printAboveInput(&"Command: {input} (try 'long' or 'short')")
  
  exitPersistentMode()
  echo "\nPaging demo completed."

proc demoTemporaryDisplay() =
  ## Demo 3: Temporary display below input area
  echo "\n=== Demo 3: Temporary Display Below Input ==="
  echo "This shows how completions can be displayed temporarily below the input"
  echo "Press Enter to continue..."
  discard stdin.readLine()
  
  initLinecross()
  enterPersistentMode()
  
  echo "\nType partial commands to see completions below input:"
  echo "Try typing '/n', '/l', '/h' or 'quit' to exit."
  
  while true:
    let input = readline("temp> ")
    let trimmed = input.strip()
    
    if trimmed.toLowerAscii() in ["quit", "exit"]:
      break
    
    # Simulate completion based on input
    if trimmed.startsWith("/n"):
      printBelow("Completions:\n  /new [title] - Create new conversation")
    elif trimmed.startsWith("/l"):
      printBelow("Completions:\n  /list - List all conversations")  
    elif trimmed.startsWith("/h"):
      printBelow("Completions:\n  /help - Show help information")
    elif trimmed.startsWith("/"):
      printBelow(createCompletionExample())
    elif trimmed.len > 0:
      printAboveInput(&"Executed: {trimmed}")
      clearBelow()  # Clear temporary completions
    else:
      clearBelow()  # Clear on empty input
  
  exitPersistentMode()
  echo "\nTemporary display demo completed."

proc demoInteractiveSession() =
  ## Demo 4: Full interactive session simulating Niffler usage
  echo "\n=== Demo 4: Interactive Session (Niffler Simulation) ==="
  echo "This simulates how Niffler would use the enhanced linecross"
  echo "Press Enter to continue..."
  discard stdin.readLine()
  
  initLinecross()
  enterPersistentMode()
  
  # Show initial help
  let welcomeMsg = """Welcome to Enhanced Niffler Demo!
  
Available commands:
  /conv           - Show conversation table
  /new <title>    - Create new conversation  
  /switch <id>    - Switch conversation
  /models         - Show available models
  help           - Show this help
  quit           - Exit demo

The input area stays fixed at bottom while output appears above."""
  
  printAboveInput(welcomeMsg)
  
  while true:
    let input = readline("niffler> ")
    let parts = input.strip().split(' ')
    let cmd = parts[0].toLowerAscii()
    
    case cmd:
    of "/conv":
      let table = createSampleTable()
      printAboveInput("Current conversations:\n" & table)
    of "/new":
      let title = if parts.len > 1: parts[1..^1].join(" ") else: "Untitled"
      printAboveInput(&"Created new conversation: '{title}' (ID: 24)")
    of "/switch":
      let id = if parts.len > 1: parts[1] else: "?"
      printAboveInput(&"Switched to conversation ID: {id}")
    of "/models":
      let models = """Available Models:
┌─────────────┬────────────────────┬───────────┬─────────────┐
│ Nickname    │ Base URL           │ Max Tokens│ Temperature │
├─────────────┼────────────────────┼───────────┼─────────────┤
│ gpt4        │ api.openai.com     │ 128000    │ 0.7         │
│ claude      │ api.anthropic.com  │ 200000    │ 0.8         │  
│ local-llm   │ localhost:8080     │ 32000     │ Default     │
└─────────────┴────────────────────┴───────────┴─────────────┘"""
      printAboveInput(models)
    of "help":
      printAboveInput(welcomeMsg)
    of "quit", "exit":
      break
    of "":
      clearBelow()  # Clear any temporary displays on empty input
    else:
      # Simulate AI response
      let response = &"""AI Response to: "{input}"

This is a simulated AI response that demonstrates how actual 
conversation content would appear above the input area, keeping
the input prompt always visible and accessible at the bottom.

The cursor positioning issue with tables is now solved!"""
      printAboveInput(response)
  
  exitPersistentMode()
  echo "\nInteractive session demo completed."

proc main() =
  echo "Enhanced Linecross Persistent Input Area Demos"
  echo "=============================================="
  echo ""
  echo "These demos show the new functionality that solves the cursor"
  echo "positioning issue with Nancy tables and provides a foundation"
  echo "for better completion display."
  echo ""
  
  # Run all demos
  demoBasicPersistentMode()
  demoPagingFunctionality() 
  demoTemporaryDisplay()
  demoInteractiveSession()
  
  echo ""
  echo "🎉 All demos completed!"
  echo ""
  echo "Key benefits demonstrated:"
  echo "• Tables display above input without disrupting cursor position"
  echo "• Input area remains persistent and always accessible"
  echo "• Automatic paging for content that exceeds screen height"
  echo "• Temporary completions can be shown below input area"
  echo "• Seamless transition between normal and persistent modes"

when isMainModule:
  main()