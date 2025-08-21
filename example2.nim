## Example2 demonstrating Crossline features
## Port of the original example2.c

import linecross, terminal, strformat, strutils

proc completionHook(buf: string, completions: var Completions) =
  ## Completion callback with color support
  let commands = @[
    "INSERT", "SELECT", "UPDATE", "DELETE", "CREATE", "DROP", "SHOW", "DESCRIBE", 
    "help", "exit", "history", "paging", "color"
  ]
  
  let commandHelp = @[
    "Insert a record to table ",
    "Select records from table",
    "Update records in table  ",
    "Delete records from table",
    "Create index on table    ",
    "Drop index or table      ",
    "Show tables or databases ",
    "Show table schema        ",
    "Show help for topic      ",
    "Exit shell               ",
    "Show history             ",
    "Do paing APIs test       ",
    "Do Color APIs test       "
  ]
  
  for i, cmd in commands:
    if cmd.toLowerAscii().startsWith(buf.toLowerAscii()):
      let wcolor = if i < 8: fgYellow else: fgCyan
      let hcolor = if i mod 2 != 0: fgWhite else: fgCyan
      addCompletion(completions, cmd, commandHelp[i], wcolor, hcolor)

proc pagingTest() =
  ## Test paging functionality
  enablePaging(true)
  for i in 0..<256:
    echo &"Paging test: {i:3}"
    if checkPaging():
      break

proc colorTest() =
  ## Test color functionality
  echo "\n*** Color test *** \n"
  echo "  Default Foreground and Background\n\n"

  setTextColor(fgWhite)
  echo "  Foregroud: Black"
  setTextColor(ColorDefault)
  echo ""
  setTextColor(fgRed)
  echo "  Foregroud: Red Underline"
  setTextColor(fgGreen)
  echo "  Foregroud: Green"
  setTextColor(fgYellow)
  echo "  Foregroud: Yellow"
  setTextColor(fgBlue)
  echo "  Foregroud: Blue"
  setTextColor(fgMagenta)
  echo "  Foregroud: Magenta"
  setTextColor(fgCyan)
  echo "  Foregroud: Cyan"
  setTextColor(fgWhite)
  echo "  Foregroud: White"
  setTextColor(ColorDefault)
  echo "\n"

  setTextColor(fgWhite)
  echo "  Foregroud: Bright Black"
  setTextColor(ColorDefault)
  echo ""
  setTextColor(fgRed)
  echo "  Foregroud: Bright Red"
  setTextColor(fgGreen)
  echo "  Foregroud: Bright Green"
  setTextColor(fgYellow)
  echo "  Foregroud: Bright Yellow"
  setTextColor(fgBlue)
  echo "  Foregroud: Bright Blue"
  setTextColor(fgMagenta)
  echo "  Foregroud: Bright Magenta"
  setTextColor(fgCyan)
  echo "  Foregroud: Bright Cyan Underline"
  setTextColor(fgWhite)
  echo "  Foregroud: Bright White\n"

  setTextColor(fgWhite)
  echo "  Backgroud: Black   "
  setTextColor(ColorDefault)
  echo ""
  setTextColor(fgRed)
  echo "  Backgroud: Red     "
  setTextColor(ColorDefault)
  echo ""
  setTextColor(fgGreen)
  echo "  Backgroud: Green   "
  setTextColor(ColorDefault)
  echo ""
  setTextColor(fgYellow)
  echo "  Backgroud: Yellow  "
  setTextColor(ColorDefault)
  echo ""
  setTextColor(fgBlue)
  echo "  Backgroud: Blue    "
  setTextColor(ColorDefault)
  echo ""
  setTextColor(fgMagenta)
  echo "  Backgroud: Magenta "
  setTextColor(ColorDefault)
  echo ""
  setTextColor(fgCyan)
  echo "  Backgroud: Cyan    "
  setTextColor(ColorDefault)
  echo ""
  setTextColor(fgWhite)
  echo "  Backgroud: White   "
  setTextColor(ColorDefault)
  echo "\n"

  setTextColor(fgWhite)
  echo "  Backgroud: Bright Black   "
  setTextColor(ColorDefault)
  echo ""
  setTextColor(fgRed)
  echo "  Backgroud: Bright Red     "
  setTextColor(ColorDefault)
  echo ""
  setTextColor(fgGreen)
  echo "  Backgroud: Bright Green   "
  setTextColor(ColorDefault)
  echo ""
  setTextColor(fgYellow)
  echo "  Backgroud: Bright Yellow  "
  setTextColor(ColorDefault)
  echo ""
  setTextColor(fgBlue)
  echo "  Backgroud: Bright Blue    "
  setTextColor(ColorDefault)
  echo ""
  setTextColor(fgMagenta)
  echo "  Backgroud: Bright Magenta "
  setTextColor(ColorDefault)
  echo ""
  setTextColor(fgCyan)
  echo "  Backgroud: Bright Cyan    "
  setTextColor(ColorDefault)
  echo ""
  setTextColor(fgWhite)
  echo "  Backgroud: Bright White   "
  setTextColor(ColorDefault)
  echo ""

proc main() =
  echo "Crossline for Nim - Example2"
  echo "Type 'exit' to quit"
  echo ""
  
  # Set up completion
  registerCompletionCallback(completionHook)
  
  # Load history
  discard loadHistory("history.txt")
  
  # Set prompt color
  setPromptColor(fgGreen)
  
  # Readline with initial text input
  var buf = "select "
  let line = readline("Crossline> ", buf)
  if line != "":
    echo &"Read line: \"{line}\""
  
  # Readline loop
  while true:
    try:
      let line = readline("Crossline> ")
      
      if line == "":
        echo "Goodbye!"
        break
      
      echo &"Read line: \"{line}\""
      
      if line == "history":
        # TODO: Add a public function to show history
        echo "History display not implemented yet."
      elif line == "paging":
        pagingTest()
      elif line == "color":
        colorTest()
      elif line == "exit":
        echo "Goodbye!"
        break
    
    except EOFError:
      echo "\nGoodbye!"
      break
  
  # Save history
  discard saveHistory("history.txt")

when isMainModule:
  main()