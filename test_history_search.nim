## Test program for linecross with history search feature

import linecross

proc main() =
  # Initialize with history search enabled
  echo "Testing linecross with incremental history search"
  initLinecross(enableHistory = true, enableHistorySearch = true)
  
  # Add some test history entries
  addToHistory("help")
  addToHistory("list files")
  addToHistory("grep pattern")
  addToHistory("find . -name '*.nim'")
  addToHistory("nim c -r test.nim")
  addToHistory("git status")
  addToHistory("git commit -m 'test'")
  
  echo "Test history added. Available commands:"
  let history = lookupHistory("")  # Get all history entries
  for i, entry in history:
    echo "  ", i+1, ": ", entry
  
  echo ""
  echo "Interactive test:"
  echo "- Try normal input and history navigation (Up/Down arrows)"
  echo "- Try incremental history search with Ctrl-R"
  echo "- Type 'quit' to exit"
  echo ""
  
  while true:
    let input = readline("test> ")
    
    if input == "quit" or input == "":
      break
    elif input == "history":
      echo "Current history:"
      let currentHistory = lookupHistory("")  # Get all history entries
      for i, entry in currentHistory:
        echo "  ", i+1, ": ", entry
    else:
      echo "You entered: ", input

  echo "Test completed successfully!"

when isMainModule:
  main()