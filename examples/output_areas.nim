## Example demonstrating status area, info area, and scrolling output
import ../linecross
import times, strutils, os, sequtils

# Simple completion callback that also uses info area
proc completionWithInfo(buffer: string, cursorPos: int, isSecondTab: bool): string =
  let prefix = buffer[0..<cursorPos]
  
  if isSecondTab:
    # Show completions in info area on second tab
    let matches = @["file.nim", "folder/", "readme.md", "config.json"]
    let filtered = matches.filterIt(it.startsWith(prefix))
    if filtered.len > 0:
      setInfo(@["Available completions:"] & filtered.mapIt("  " & it))
      redraw()
    else:
      setInfo(@["No matches for: " & prefix])
      redraw()
    return ""
  else:
    # Try simple completion on first tab
    let matches = @["file.nim", "folder/", "readme.md", "config.json"]
    let filtered = matches.filterIt(it.startsWith(prefix))
    if filtered.len == 1:
      # Single match - complete it
      return filtered[0][prefix.len..^1]
    elif filtered.len > 1:
      # Multiple matches - find common prefix
      if filtered.len > 0:
        var common = filtered[0]
        for match in filtered[1..^1]:
          while common.len > prefix.len and not match.startsWith(common):
            common = common[0..^2]
        if common.len > prefix.len:
          return common[prefix.len..^1]
  
  return ""

proc updateStatus() =
  let now = now()
  let timeStr = now.format("HH:mm:ss")
  let dateStr = now.format("yyyy-MM-dd")
  setStatus(@[
    "Linecross Demo - " & dateStr & " " & timeStr,
    "Directory: " & getCurrentDir(),
    "PID: " & $getCurrentProcessId()
  ])

proc main() =
  echo "Linecross Output Areas Demo"
  echo "============================="
  echo ""
  echo "Features:"
  echo "- Status area above prompt (updates with time/info)"
  echo "- Info area below prompt (shows completions on double-tab)"
  echo "- Scrolling output (normal terminal output)"
  echo ""
  echo "Commands:"
  echo "  time - show current time in output"
  echo "  demo - demonstrate all areas"
  echo "  clear - clear status and info areas"
  echo "  help - show this help"
  echo "  quit - exit"
  echo ""
  
  # Initialize with history and completion
  initLinecross(enableHistory = true)
  registerCompletionCallback(completionWithInfo)
  
  # Initial status
  updateStatus()
  redraw()
  
  while true:
    let input = readline("> ")
    
    case input:
    of "quit", "exit":
      break
    of "time":
      writeOutput("Current time: " & now().format("yyyy-MM-dd HH:mm:ss"))
    of "demo":
      writeOutput("Demonstrating all areas...")
      setStatus(@["Demo Mode Active", "Status updates here", "Multiple lines supported"])
      setInfo(@["Info area example", "Shows completions", "Or other contextual info"])
      redraw()
      writeOutput("Status area (above) and info area (below) are now visible!")
    of "clear":
      clearStatus()
      clearInfo()
      redraw()
      writeOutput("Status and info areas cleared")
    of "help":
      writeOutput("Available commands: time, demo, clear, help, quit")
      writeOutput("Try using TAB completion (double-tap for options)")
    of "":
      # Empty input - just update status with current time
      updateStatus()
      redraw()
    else:
      writeOutput("Echo: " & input)
      # Update status with command count or other info
      updateStatus()
      redraw()

when isMainModule:
  main()