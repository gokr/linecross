## Tab Completion Example
##
## This example demonstrates tab completion features including:
## - Single tab completion for unique matches
## - Double tab to show all possible completions
## - Context-aware completions

import ../linecross
import std/[strutils, sequtils]

# File operation commands for demonstration
let fileCommands = @[
  "open", "save", "close", "list", "create", "delete",
  "copy", "move", "rename", "search", "help", "exit"
]

proc fileCompletionCallback(buffer: string, cursorPos: int, isSecondTab: bool): string =
  ## File command completion callback
  # Find current word
  var wordStart = cursorPos
  while wordStart > 0 and buffer[wordStart - 1] notin [' ', '\t']:
    dec wordStart
  
  let currentWord = if wordStart < cursorPos: buffer[wordStart..<cursorPos] else: ""
  
  if not isSecondTab:
    # First tab - try to complete
    var matches: seq[string] = @[]
    for cmd in fileCommands:
      if cmd.startsWith(currentWord.toLowerAscii()):
        matches.add(cmd)
    
    if matches.len == 1:
      return matches[0][currentWord.len..^1]  # Complete the match
    elif matches.len > 1:
      return ""  # Wait for second tab
  else:
    # Second tab - show matches with help
    var matches: seq[string] = @[]
    for cmd in fileCommands:
      if cmd.startsWith(currentWord.toLowerAscii()):
        matches.add(cmd)
    
    if matches.len > 1:
      echo "\nFile operations:"
      for cmd in matches:
        let helpText = case cmd:
          of "open": "Open a file for editing"
          of "save": "Save the current file"
          of "list": "List files in directory"
          of "create": "Create a new file"
          of "delete": "Delete a file"
          of "copy": "Copy file to new location"
          of "move": "Move/rename a file"
          of "search": "Search within files"
          else: "Command: " & cmd
        echo "  ", cmd, " - ", helpText
      echo ""
  
  return ""

proc sqlCompletionCallback(buffer: string, cursorPos: int, isSecondTab: bool): string =
  ## SQL-like completion callback with context awareness
  let sqlCommands = @["SELECT", "INSERT", "UPDATE", "DELETE", "CREATE", "DROP", "SHOW", "DESCRIBE"]
  let sqlClauses = @["WHERE", "FROM", "INTO", "SET", "ORDER BY", "LIMIT"]
  
  let tokens = buffer.splitWhitespace()
  let numTokens = tokens.len
  let lastChar = if buffer.len > 0: buffer[^1] else: '\0'
  
  # Find current word
  var wordStart = cursorPos
  while wordStart > 0 and buffer[wordStart - 1] notin [' ', '\t']:
    dec wordStart
  
  let currentWord = if wordStart < cursorPos: buffer[wordStart..<cursorPos] else: ""
  
  if not isSecondTab:
    # First tab completion
    var matches: seq[string] = @[]
    
    # If at start or no space after first word, suggest SQL commands
    if numTokens <= 1 and lastChar != ' ':
      for cmd in sqlCommands:
        if cmd.toLowerAscii().startsWith(currentWord.toLowerAscii()):
          matches.add(cmd)
    else:
      # Context-aware completions based on command
      if numTokens >= 1:
        let command = tokens[0].toUpperAscii()
        case command:
        of "SELECT":
          if lastChar == ' ':
            matches.add("FROM")
            for clause in sqlClauses:
              if clause != "FROM" and clause != "INTO" and clause != "SET":
                matches.add(clause)
        of "INSERT":
          if lastChar == ' ':
            matches.add("INTO")
        of "UPDATE", "DELETE":
          if lastChar == ' ':
            for clause in sqlClauses:
              if clause != "INTO":
                matches.add(clause)
        else:
          matches = sqlClauses
    
    if matches.len == 1:
      return matches[0][currentWord.len..^1]
    elif matches.len > 1:
      return ""
  else:
    # Second tab - show matches
    var matches: seq[string] = @[]
    
    if numTokens <= 1 and lastChar != ' ':
      for cmd in sqlCommands:
        if cmd.toLowerAscii().startsWith(currentWord.toLowerAscii()):
          matches.add(cmd)
    else:
      if numTokens >= 1:
        let command = tokens[0].toUpperAscii()
        case command:
        of "SELECT":
          matches = @["FROM"] & sqlClauses.filterIt(it notin ["FROM", "INTO", "SET"])
        of "INSERT":
          matches = @["INTO", "SET"]
        of "UPDATE", "DELETE":
          matches = sqlClauses.filterIt(it != "INTO")
        else:
          matches = sqlClauses
    
    if matches.len > 0:
      echo "\nSQL completions:"
      for match in matches:
        echo "  ", match
      echo ""
  
  return ""

# Forward declaration
proc runSqlDemo()

proc runFileDemo() =
  echo "=== File Operations Completion Demo ==="
  echo "Available commands: ", fileCommands.join(", ")
  echo "Try typing partial commands and pressing Tab"
  echo "Examples: 'o<Tab>', 's<Tab><Tab>', 'cr<Tab>'"
  echo "Type 'sql' to switch to SQL demo, 'quit' to exit"
  echo ""
  
  registerCompletionCallback(fileCompletionCallback)
  
  while true:
    let input = readline("file> ")
    
    case input.strip():
    of "quit", "exit":
      break
    of "sql":
      echo "Switching to SQL demo..."
      runSqlDemo()
      return
    of "help":
      echo "File commands help:"
      for cmd in fileCommands:
        echo "- ", cmd, ": File operation"
    else:
      if input.len > 0:
        let parts = input.split(' ')
        echo "Command: ", parts[0]
        if parts.len > 1:
          echo "Arguments: ", parts[1..^1].join(" ")

proc runSqlDemo() =
  echo "\n=== SQL Completion Demo ==="
  echo "Context-aware SQL completions"
  echo "Try: 'SELECT <Tab>', 'INSERT <Tab>', 'UPDATE <Tab>'"
  echo "Type 'file' to switch back, 'quit' to exit"
  echo ""
  
  registerCompletionCallback(sqlCompletionCallback)
  
  while true:
    let input = readline("SQL> ")
    
    case input.strip():
    of "quit", "exit":
      break
    of "file":
      echo "Switching back to file demo..."
      runFileDemo()
      return
    of "help":
      echo "SQL patterns to try:"
      echo "- SELECT <Tab> - shows FROM and clauses"
      echo "- INSERT <Tab> - shows INTO"
      echo "- UPDATE/DELETE <Tab> - shows clauses"
    else:
      if input.len > 0:
        echo "SQL statement: ", input

proc main() =
  echo "Tab Completion Examples"
  echo "======================"
  echo ""
  echo "This demonstrates two completion styles:"
  echo "1. Simple command completion with help"
  echo "2. Context-aware SQL-like completion"
  echo ""
  echo "Completion behavior:"
  echo "- Single Tab: Complete if unique, wait if multiple"
  echo "- Double Tab: Show all possible completions"
  echo ""
  
  initLinecross(enableHistory = true)
  runFileDemo()
  
  echo "Completion examples completed!"

when isMainModule:
  main()