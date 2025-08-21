## Example SQL demonstrating Linecross features
## Port of the original example_sql.c

import linecross, std/terminal
import strformat, strutils

proc sqlAddCompletion(completions: var Completions, prefix: string, 
                     matches: seq[string], help: seq[string] = @[]) =
  ## Add SQL completions with optional help text
  let len = prefix.len
  for i, match in matches:
    if match.toLowerAscii().startsWith(prefix.toLowerAscii()):
      if help.len > 0 and i < help.len:
        let wcolor = if i < 8: fgYellow else: fgCyan
        let hcolor = if i mod 2 != 0: fgWhite else: fgCyan
        addCompletion(completions, match, help[i], wcolor, hcolor)
      else:
        addCompletion(completions, match, "", fgMagenta, fgDefault)

proc sqlFindKey(matches: seq[string], key: string): int =
  ## Find index of key in matches, case insensitive
  for i, match in matches:
    if match.toLowerAscii() == key.toLowerAscii():
      return i
  return -1

proc sqlCompletionHook(buf: string, completions: var Completions) =
  ## SQL completion callback with syntax parsing
  let sqlCmd = @[
    "INSERT", "SELECT", "UPDATE", "DELETE", "CREATE", "DROP", "SHOW", "DESCRIBE", 
    "help", "exit", "history"
  ]
  
  let sqlCmdHelp = @[
    "Insert a record to table",
    "Select records from table",
    "Update records in table",
    "Delete records from table",
    "Create index on table",
    "Drop index or table",
    "Show tables or databases",
    "Show table schema",
    "Show help for topic",
    "Exit shell",
    "Show history"
  ]
  
  let sqlClause = @["WHERE", "ORDER BY", "LIMIT", "OFFSET"]
  let sqlIndex = @["UNIQUE", "INDEX"]
  let sqlDrop = @["TABLE", "INDEX"]
  let sqlShow = @["TABLES", "DATABASES"]
  
  let tblColor = fgGreen
  let colColor = fgCyan
  let idxColor = fgYellow
  
  # Split buffer into tokens
  let tokens = buf.splitWhitespace()
  let numTokens = tokens.len
  let lastChar = if buf.len > 0: buf[^1] else: '\0'
  
  # Find command
  let cmd = if numTokens > 0: sqlFindKey(sqlCmd, tokens[0]) else: -1
  
  # If no command yet, suggest commands
  if cmd < 0 and numTokens <= 1:
    sqlAddCompletion(completions, buf, sqlCmd, sqlCmdHelp)
  
  # Handle specific commands
  case cmd:
  of 0: # INSERT INTO <table> SET column1=value1,column2=value2,...
    if numTokens == 1 and lastChar == ' ':
      addCompletion(completions, "INTO", "")
    elif numTokens == 2 and lastChar == ' ':
      setHints(completions, "table name", tblColor)
    elif numTokens == 3 and lastChar == ' ':
      addCompletion(completions, "SET", "")
    elif numTokens == 4 and lastChar == ' ':
      setHints(completions, "column1=value1,column2=value2,...", colColor)
  
  of 1: # SELECT <* | column1,columnm2,...> FROM <table> [WHERE] [ORDER BY] [LIMIT] [OFFSET]
    if numTokens == 1 and lastChar == ' ':
      setHints(completions, "* | column1,columnm2,...", colColor)
    elif numTokens == 2 and lastChar == ' ':
      addCompletion(completions, "FROM", "")
    elif numTokens == 3 and lastChar == ' ':
      setHints(completions, "table name", tblColor)
    elif numTokens == 4 and lastChar == ' ':
      sqlAddCompletion(completions, "", sqlClause)
    elif numTokens > 4 and lastChar != ' ':
      sqlAddCompletion(completions, tokens[^1], sqlClause)
  
  of 2: # UPDATE <table> SET column1=value1,column2=value2 [WHERE] [ORDER BY] [LIMIT] [OFFSET]
    if numTokens == 1 and lastChar == ' ':
      setHints(completions, "table name", tblColor)
    elif numTokens == 2 and lastChar == ' ':
      addCompletion(completions, "SET", "")
    elif numTokens == 3 and lastChar == ' ':
      setHints(completions, "column1=value1,column2=value2,...", colColor)
    elif numTokens == 4 and lastChar == ' ':
      sqlAddCompletion(completions, "", sqlClause)
    elif numTokens > 4 and lastChar != ' ':
      sqlAddCompletion(completions, tokens[^1], sqlClause)
  
  of 3: # DELETE FROM <table> [WHERE] [ORDER BY] [LIMIT] [OFFSET]
    if numTokens == 1 and lastChar == ' ':
      addCompletion(completions, "FROM", "")
    elif numTokens == 2 and lastChar == ' ':
      setHints(completions, "table name", tblColor)
    elif numTokens == 3 and lastChar == ' ':
      sqlAddCompletion(completions, "", sqlClause)
    elif numTokens > 3 and lastChar != ' ':
      sqlAddCompletion(completions, tokens[^1], sqlClause)
  
  of 4: # CREATE [UNIQUE] INDEX <name> ON <table> (column1,column2,...)
    var bUnique = false
    if numTokens == 1 and lastChar == ' ':
      sqlAddCompletion(completions, "", sqlIndex)
    elif numTokens == 2 and lastChar != ' ':
      sqlAddCompletion(completions, tokens[1], sqlIndex)
    else:
      if numTokens >= 2 and tokens[1].toLowerAscii() == "unique":
        bUnique = true
      
      if numTokens == 2 and bUnique and lastChar == ' ':
        addCompletion(completions, "INDEX", "")
      elif numTokens == 2 + (if bUnique: 1 else: 0) and lastChar == ' ':
        setHints(completions, "index name", idxColor)
      elif numTokens == 3 + (if bUnique: 1 else: 0) and lastChar == ' ':
        addCompletion(completions, "ON", "")
      elif numTokens == 4 + (if bUnique: 1 else: 0) and lastChar == ' ':
        setHints(completions, "table name", tblColor)
      elif numTokens == 5 + (if bUnique: 1 else: 0) and lastChar == ' ':
        setHints(completions, "(column1,column2,...)", colColor)
  
  of 5: # DROP TABLE <name>, DROP INDEX <name>
    if numTokens == 1 and lastChar == ' ':
      sqlAddCompletion(completions, "", sqlDrop)
    elif numTokens == 2 and lastChar != ' ':
      sqlAddCompletion(completions, tokens[1], sqlDrop)
    elif numTokens == 2 and lastChar == ' ':
      if tokens[1].toLowerAscii() == "table":
        setHints(completions, "table name", tblColor)
      elif tokens[1].toLowerAscii() == "index":
        setHints(completions, "index name", idxColor)
  
  of 6: # SHOW TABLES, SHOW DATABASES
    if numTokens == 1 and lastChar == ' ':
      sqlAddCompletion(completions, "", sqlShow)
    elif numTokens == 2 and lastChar != ' ':
      sqlAddCompletion(completions, tokens[1], sqlShow)
  
  of 7: # DESCRIBE <table>
    if lastChar == ' ':
      setHints(completions, "table name", tblColor)
  
  of 8: # help
    if numTokens == 1 and lastChar == ' ':
      sqlAddCompletion(completions, "", sqlCmd)
    elif numTokens == 2 and lastChar != ' ':
      sqlAddCompletion(completions, tokens[1], sqlCmd)
  
  of 9: # exit
    discard
  
  else:
    discard

proc main() =
  echo "Linecross for Nim - SQL Example"
  echo "This Example implements a simple SQL syntax parser."
  echo ""
  echo "  INSERT INTO <table> SET column1=value1,column2=value2,..."
  echo "  SELECT <* | column1,columnm2,...> FROM <table> [WHERE] [ORDER BY] [LIMIT] [OFFSET]"
  echo "  UPDATE <table> SET column1=value1,column2=value2 [WHERE] [ORDER BY] [LIMIT] [OFFSET]"
  echo "  DELETE FROM <table> [WHERE] [ORDER BY] [LIMIT] [OFFSET]"
  echo "  CREATE [UNIQUE] INDEX <name> ON <table> (column1,column2,...)"
  echo "  DROP {TABLE | INDEX} <name>"
  echo "  SHOW {TABLES | DATABASES}"
  echo "  DESCRIBE <TABLE>"
  echo "  help {INSERT | SELECT | UPDATE | DELETE | CREATE | DROP | SHOW | DESCRIBE | help | exit | history}"
  echo ""
  echo "Type 'exit' to quit"
  echo ""
  
  # Set up completion
  registerCompletionCallback(sqlCompletionHook)
  
  # Load history
  discard loadHistory("history.txt")
  
  # Set prompt color
  setPromptColor(fgGreen)
  
  # Main loop
  while true:
    try:
      let line = readline("SQL> ")
      
      if line == "":
        echo "Goodbye!"
        break
      
      echo &"Read line: \"{line}\""
      
      if line == "history":
        # TODO: Add a public function to show history
        echo "History display not implemented yet."
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