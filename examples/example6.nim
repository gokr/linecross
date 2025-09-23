## Custom History Callbacks Example for Linecross
##
## This example demonstrates how to implement custom history callbacks
## to replace the built-in file-based history with your own storage system

import linecross
import std/[strutils, tables, times]

# Custom history storage - could be database, network, etc.
var customHistoryStorage: seq[string] = @[]
var historyMetadata: Table[string, string] = initTable[string, string]()

proc customHistoryLoad(): seq[string] {.nimcall.} =
  ## Custom history loader - could load from database, API, etc.
  echo "Loading history from custom storage..."
  
  # Simulate loading from external source
  # In real use, this might be database queries, API calls, etc.
  result = customHistoryStorage
  echo "Loaded ", result.len, " history entries"

proc customHistorySave(entries: seq[string]): bool {.nimcall.} =
  ## Custom history saver - could save to database, API, etc.
  echo "Saving ", entries.len, " history entries to custom storage..."
  
  # Simulate saving to external source
  customHistoryStorage = entries
  
  # Add metadata for each entry
  let timestamp = $now()
  for entry in entries:
    historyMetadata[entry] = timestamp
    
  echo "History saved successfully with metadata"
  return true

proc customHistoryLookup(pattern: string, maxResults: int): seq[string] {.nimcall.} =
  ## Custom history search - could implement fuzzy matching, ranking, etc.
  echo "Searching history for pattern: '", pattern, "'"
  
  var results: seq[string] = @[]
  
  # Custom search logic - could be fuzzy matching, regex, etc.
  for entry in customHistoryStorage:
    if pattern.len == 0 or entry.toLowerAscii().contains(pattern.toLowerAscii()):
      results.add(entry)
      if results.len >= maxResults:
        break
  
  # Could sort by relevance, recency, etc.
  echo "Found ", results.len, " matching entries"
  return results

proc showHistoryMetadata() =
  ## Show stored metadata about history entries
  echo "\nHistory Metadata:"
  for entry, timestamp in historyMetadata:
    echo "  '", entry, "' -> ", timestamp

proc completionHook(buf: string, completions: var Completions) =
  ## Example completion with commands for testing
  let commands = @[
    "test_history", "show_metadata", "search_test", 
    "help", "exit"
  ]
  
  for cmd in commands:
    if cmd.startsWith(buf.split(' ')[^1]):
      addCompletion(completions, cmd, "Demo command: " & cmd)

proc main() =
  echo "Linecross Custom History Callbacks Demo"
  echo "======================================="
  echo ""
  echo "This example shows how to implement custom history callbacks"
  echo "to replace the built-in file-based history system."
  echo ""
  
  # Initialize Linecross with basic features  
  initLinecross(BasicFeatures)
  
  # Register our custom history callbacks
  registerHistorySaveCallback(customHistorySave)
  registerHistoryLookupCallback(customHistoryLookup)
  
  # Pre-populate some example history data
  customHistoryStorage = @[
    "echo hello world", 
    "ls -la", 
    "git status", 
    "nim c -r example.nim",
    "cat README.md"
  ]
  
  # Load history using our custom loader and set it
  setHistoryEntries(customHistoryLoad())
  
  # Register completion
  registerCompletionCallback(completionHook)
  
  echo "Custom history callbacks are now active!"
  echo ""
  echo "Available commands:"
  echo "- test_history: Add some test entries to history"
  echo "- show_metadata: Display history metadata"  
  echo "- search_test: Test custom history search"
  echo "- help: Show this help"
  echo "- exit: Quit"
  echo ""
  echo "Try pressing Up/Down to navigate the pre-loaded history"
  echo ""
  
  # Main readline loop
  while true:
    let line = readline("Custom> ")
    
    if line == "exit":
      break
    elif line == "test_history":
      echo "Adding test entries to history..."
      addToHistory("test command 1")
      addToHistory("test command 2")  
      addToHistory("test command 3")
      echo "Test entries added. Try Up arrow to see them."
    elif line == "show_metadata":
      showHistoryMetadata()
    elif line == "search_test":
      let searchPattern = readline("Enter search pattern: ")
      let results = lookupHistory(searchPattern, 10)
      echo "Search results for '", searchPattern, "':"
      for i, result in results:
        echo "  ", i + 1, ". ", result
    elif line == "help":
      echo """
Custom History Callbacks Help:

This example demonstrates three types of custom history callbacks:

1. HistoryLoadCallback - Called when history needs to be loaded
   - Can load from database, API, file system, etc.
   - Should return seq[string] of history entries

2. HistorySaveCallback - Called when history needs to be saved  
   - Receives seq[string] of current history entries
   - Should return true if save was successful
   - Can save to database, API, file system, etc.

3. HistoryLookupCallback - Called when searching history
   - Receives search pattern and max results count
   - Should return seq[string] of matching entries
   - Can implement fuzzy matching, ranking, etc.

To use custom callbacks in your application:
1. Define callback procedures matching the expected signatures
2. Register them using registerHistorySaveCallback() etc after initLinecross()
3. The Linecross library will use your callbacks instead of built-in file operations

Example:
  registerHistorySaveCallback(myCustomSave)
"""
    else:
      echo "You entered: '", line, "'"
      echo "This will be saved using the custom history callback"
  
  # Save history using our custom saver when exiting
  # Note: The library automatically calls the save callback, but we can also call it manually
  echo "Manually saving history before exit..."
  discard customHistorySave(getHistoryEntries())
  echo "Custom history callbacks demo completed!"

when isMainModule:
  main()