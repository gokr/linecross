## Live demonstration of output areas functionality
## Shows how output and status can be updated while maintaining input area
import ../linecross
import times, strutils, os, sequtils, random

var
  messageCount = 0
  commandCount = 0
  demoMode = false

proc updateStatus() =
  let now = times.now()
  let timeStr = now.format("HH:mm:ss")
  let dateStr = now.format("MMM dd")
  
  var statusLines = @[
    "🕐 " & dateStr & " " & timeStr,
    "📁 " & getCurrentDir().extractFilename,
    "📊 Commands: " & $commandCount & " | Messages: " & $messageCount
  ]
  
  if demoMode:
    statusLines.add("🔥 DEMO MODE ACTIVE")
  
  setStatus(statusLines)

proc simulateBackgroundActivity() =
  # Simulate some background activity with output
  if demoMode and rand(1..10) <= 3:  # 30% chance
    let activities = [
      "Processing background task...",
      "Network heartbeat received",
      "Cache updated successfully",
      "Monitoring system health",
      "Auto-save completed",
      "Log rotation finished"
    ]
    let activity = activities[rand(activities.high)]
    writeOutput("🔄 [AUTO] " & activity)
    inc messageCount
    updateStatus()

proc completionCallback(buffer: string, cursorPos: int, isSecondTab: bool): string =
  let prefix = buffer[0..<cursorPos]
  let commands = @["help", "status", "demo", "spam", "clear", "time", "quit", "info"]
  
  if isSecondTab:
    # Show completions in info area
    let matches = commands.filterIt(it.startsWith(prefix))
    if matches.len > 0:
      setInfo(@["💡 Available commands:"] & matches.mapIt("  " & it & " - press TAB to complete"))
    else:
      setInfo(@["❌ No commands match '" & prefix & "'"])
    redraw()
    return ""
  else:
    # Try to complete on first tab
    let matches = commands.filterIt(it.startsWith(prefix))
    if matches.len == 1:
      return matches[0][prefix.len..^1]
    elif matches.len > 1:
      # Find common prefix
      var common = matches[0]
      for cmd in matches[1..^1]:
        while common.len > prefix.len and not cmd.startsWith(common):
          common = common[0..^2]
      if common.len > prefix.len:
        return common[prefix.len..^1]
  return ""

proc main() =
  randomize()
  echo "Live Linecross Demo"
  echo "=================="
  echo ""
  echo "This demo shows real-time updates to:"
  echo "• Status area (top) - time, directory, counters" 
  echo "• Output area (scrolling) - messages and responses"
  echo "• Info area (bottom) - completions on double-TAB"
  echo ""
  echo "Commands: help, demo, spam, clear, time, quit"
  echo "Try typing and using TAB completion!"
  echo ""
  
  # Initialize linecross
  initLinecross(enableHistory = true, moveCursorOnEnter = false)
  registerCompletionCallback(completionCallback)
  
  # Set initial status
  updateStatus()
  redraw()
  
  while true:
    # Simulate background activity occasionally
    simulateBackgroundActivity()
    
    let input = readline("➤ ")
    inc commandCount
    
    case input.toLower():
    of "quit", "exit", "q":
      writeOutput("👋 Goodbye!")
      break
      
    of "help", "h":
      writeOutput("📖 Available commands:")
      writeOutput("  help    - Show this help")
      writeOutput("  demo    - Toggle demo mode (auto-activity)")
      writeOutput("  spam    - Generate test messages")
      writeOutput("  clear   - Clear status and info areas")
      writeOutput("  time    - Show current time")
      writeOutput("  status  - Show detailed status")
      writeOutput("  info    - Show persistent info area")
      writeOutput("  quit    - Exit")
      writeOutput("")
      writeOutput("💡 Use TAB for completion, double-TAB to see options below!")
      
    of "demo", "d":
      demoMode = not demoMode
      let status = if demoMode: "enabled" else: "disabled"
      writeOutput("🎭 Demo mode " & status & " - background activity " & status)
      updateStatus()
      redraw()
      
    of "spam":
      writeOutput("📢 Generating test messages...")
      for i in 1..5:
        writeOutput("📝 Test message #" & $i & " - Random: " & $(rand(1000) + 1000))
        inc messageCount
      updateStatus()
      redraw()
      
    of "clear", "c":
      clearStatus()
      clearInfo()
      redraw()
      writeOutput("🧹 Status and info areas cleared")
      
    of "time", "t":
      let now = times.now()
      writeOutput("🕐 Current time: " & now.format("yyyy-MM-dd HH:mm:ss"))
      
    of "status", "s":
      writeOutput("📊 Current Status:")
      writeOutput("  Commands executed: " & $commandCount)
      writeOutput("  Messages sent: " & $messageCount)
      writeOutput("  Demo mode: " & (if demoMode: "ON" else: "OFF"))
      writeOutput("  Directory: " & getCurrentDir())
      
    of "info", "i":
      setInfo(@[
        "ℹ️  Linecross Demo Info:",
        "• Status area shows live updates",
        "• This info area is persistent", 
        "• Output scrolls normally above",
        "• Input area stays at bottom",
        "• Type 'clear' to hide this"
      ])
      redraw()
      
    of "":
      # Empty input - just update status with current time
      updateStatus() 
      redraw()
      
    else:
      if input.len > 0:
        writeOutput("❓ Unknown: '" & input & "' (try 'help')")
    
    # Always update status after each command
    updateStatus()
    redraw()

when isMainModule:
  main()