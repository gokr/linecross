## Linecross2 - Simplified Cross-platform Readline Replacement
## 
## A minimal readline implementation focusing on basic editing functionality.
## Features:
## - Basic cursor movement (left/right, home/end)
## - Character insertion and deletion
## - Multiline editing with simple full-redraw approach
## - Essential keyboard shortcuts only

import std/[terminal, strutils, strformat, os, sequtils]

## Constants
const
  DefaultHistoryMaxLines* = 256

## Callback types for extensibility
type
  CustomKeyCallback* = proc(keyCode: int, buffer: string): bool {.nimcall.}
  HistoryLoadCallback* = proc(): seq[string] {.nimcall.}
  HistorySaveCallback* = proc(entries: seq[string]): bool {.nimcall.}

## Key codes for special keys
type
  KeyCode* = enum
    KeyTab = 9
    KeyBackspace = 8
    KeyEnter = 13
    KeyEnter2 = 10  # Linux newline
    KeyEscape = 27
    KeyDel2 = 127   # Often mapped to backspace on some systems
    
    # Arrow keys
    KeyUp = 0x2000
    KeyDown = 0x2001
    KeyLeft = 0x2002
    KeyRight = 0x2003
    
    # Special keys
    KeyHome = 0x3000
    KeyEnd = 0x3001
    KeyDelete = 0x3005

## Enhanced state for readline with history, colors, and callbacks
type
  LinecrossState = object
    # Core editing state
    buf: string      # Input buffer
    pos: int         # Cursor position in buffer
    prompt: string   # Current prompt
    cols: int        # Terminal width
    lastBufferSize: int  # Track buffer size for clearing
    
    # History system
    enableHistory: bool          # Feature flag for history
    history: seq[string]         # History entries
    historyPos: int              # Current position in history
    maxHistoryLines: int         # Maximum history entries
    
    # Color and styling
    promptColor: ForegroundColor # Prompt color
    promptStyle: set[Style]      # Prompt style
    
    # Callbacks
    customKeyCallback: CustomKeyCallback
    historyLoadCallback: HistoryLoadCallback
    historySaveCallback: HistorySaveCallback

# Global state
var gState: LinecrossState

## Helper template for control keys
template ctrlKey(key: char): int = ord(key) - 0x40

proc getChar(): int =
  ## Read a single character from stdin without echo
  try:
    let ch = getch()
    return ord(ch)
  except:
    return -1

proc getKey(): int =
  ## Get a key press, handling escape sequences for arrow keys
  let ch = getChar()
  if ch == ord(KeyEscape):
    let ch1 = getChar()
    if ch1 == -1:
      return ord(KeyEscape)
    
    if ch1 == ord('['):
      let ch2 = getChar()
      case ch2:
      of ord('A'): return ord(KeyUp)
      of ord('B'): return ord(KeyDown) 
      of ord('C'): return ord(KeyRight)
      of ord('D'): return ord(KeyLeft)
      of ord('H'): return ord(KeyHome)
      of ord('F'): return ord(KeyEnd)
      of ord('1'):
        let ch3 = getChar()
        if ch3 == ord('~'):
          return ord(KeyHome)
      of ord('3'):
        let ch3 = getChar()
        if ch3 == ord('~'):
          return ord(KeyDelete)
      of ord('4'):
        let ch3 = getChar()
        if ch3 == ord('~'):
          return ord(KeyEnd)
      else:
        discard
    elif ch1 == ord('O'):
      let ch2 = getChar()
      case ch2:
      of ord('H'): return ord(KeyHome)
      of ord('F'): return ord(KeyEnd)
      else: discard
    
    return ch1
  else:
    return ch

proc clearScreen() =
  ## Clear the entire screen and move cursor to top-left
  try:
    eraseScreen()
    setCursorPos(0, 0)
  except:
    # Fallback using ANSI codes
    stdout.write("\x1b[2J\x1b[H")
    stdout.flushFile()

## Color and styling functions using std/terminal
proc setTextColor*(color: ForegroundColor = fgDefault, style: set[Style] = {}) =
  ## Set terminal text color using std/terminal
  # If caller asked for default and no style, leave terminal default (reset attrs)
  if color == fgDefault and style == {}:
    resetAttributes()
    return

  try:
    # Use terminal module when available
    setForegroundColor(color)
    if style != {}:
      setStyle(style)
  except:
    # Fallback to ANSI codes for common colors
    if color == fgDefault:
      stdout.write("\x1b[0m")
      stdout.flushFile()
      return

    var code = 39
    case color:
    of fgBlack: code = 30
    of fgRed: code = 31
    of fgGreen: code = 32
    of fgYellow: code = 33
    of fgBlue: code = 34
    of fgMagenta: code = 35
    of fgCyan: code = 36
    of fgWhite: code = 37
    else: code = 39

    stdout.write(&"\x1b[{code}m")
    stdout.flushFile()

proc setPromptColor*(color: ForegroundColor = fgDefault, style: set[Style] = {}) =
  ## Set prompt color and style
  gState.promptColor = color
  gState.promptStyle = style

proc refreshLine() =
  ## Ultra-simple refresh using save/restore cursor
  # 1. Restore to start of our input
  stdout.write("\x1b[u")  # Restore to saved position
  
  # 2. Clear based on OLD buffer size (before modification)
  let oldTotalChars = gState.prompt.len + gState.lastBufferSize
  let oldLines = if gState.cols > 0: max(1, (oldTotalChars + gState.cols - 1) div gState.cols) else: 1
  
  # Clear old content completely
  for i in 0..<oldLines:
    stdout.write("\x1b[K")  # Clear current line
    if i < oldLines - 1:
      stdout.write("\n")    # Move to next line
  
  # 3. Go back to start and redraw fresh
  stdout.write("\x1b[u")    # Restore to start again
  
  # Display prompt with color
  setTextColor(gState.promptColor, gState.promptStyle)
  stdout.write(gState.prompt)
  resetAttributes()
  
  stdout.write(gState.buf)
  
  # 4. Position cursor correctly
  stdout.write("\x1b[u")    # Back to start
  let cursorChars = gState.prompt.len + gState.pos
  let cursorLine = if gState.cols > 0: cursorChars div gState.cols else: 0
  let cursorCol = if gState.cols > 0: cursorChars mod gState.cols else: cursorChars
  
  if cursorLine > 0:
    stdout.write(&"\x1b[{cursorLine}B")
  if cursorCol > 0:
    stdout.write(&"\x1b[{cursorCol}C")
  
  # 5. Update buffer size for next refresh
  gState.lastBufferSize = gState.buf.len
  
  stdout.flushFile()

proc insertChar(ch: char, pos: int) =
  ## Insert character at position
  if pos <= gState.buf.len:
    gState.buf.insert($ch, pos)

proc deleteChar(pos: int) =
  ## Delete character at position
  if pos >= 0 and pos < gState.buf.len:
    gState.buf.delete(pos..pos)

## History management functions
proc addToHistory*(line: string) =
  ## Add a line to history
  if not gState.enableHistory or line.len == 0:
    return
  
  # Remove duplicates
  gState.history = gState.history.filterIt(it != line)
  
  # Add to end
  gState.history.add(line)
  
  # Trim if too many entries
  if gState.history.len > gState.maxHistoryLines:
    gState.history = gState.history[^gState.maxHistoryLines..^1]
  
  # Reset history position to end
  gState.historyPos = gState.history.len

proc saveHistory*(filename: string): bool =
  ## Save history to file
  if not gState.enableHistory:
    return false
    
  # If a user-provided save callback is registered, use it
  if gState.historySaveCallback != nil:
    return gState.historySaveCallback(gState.history)

  try:
    let file = open(filename, fmWrite)
    defer: file.close()

    for entry in gState.history:
      file.writeLine(entry)

    return true
  except:
    return false

proc loadHistory*(filename: string): bool =
  ## Load history from file
  if not gState.enableHistory:
    return false
    
  # If a user-provided load callback is registered, use it
  if gState.historyLoadCallback != nil:
    gState.history = gState.historyLoadCallback()
    gState.historyPos = gState.history.len
    return true

  try:
    if not fileExists(filename):
      return true

    let file = open(filename, fmRead)
    defer: file.close()

    gState.history = @[]
    for line in file.lines:
      if line.len > 0:
        gState.history.add(line)

    gState.historyPos = gState.history.len
    return true
  except:
    return false

proc clearHistory*() =
  ## Clear all history
  if gState.enableHistory:
    gState.history = @[]
    gState.historyPos = 0

proc readline*(prompt: string): string =
  ## Main readline function - accepts input with basic editing
  gState.prompt = prompt
  gState.buf = ""
  gState.pos = 0
  gState.lastBufferSize = 0
  
  # Get terminal size for proper cursor positioning
  let (cols, _) = terminalSize()
  gState.cols = cols
  
  # Save initial cursor position and display prompt
  stdout.write("\x1b[s")  # Save cursor position
  setTextColor(gState.promptColor, gState.promptStyle)
  stdout.write(gState.prompt)
  resetAttributes()
  
  # Initial refresh (just positions cursor correctly)
  refreshLine()
  
  while true:
    let key = getKey()
    
    # Check custom key callback first
    if gState.customKeyCallback != nil and gState.customKeyCallback(key, gState.buf):
      # Custom key was handled - refresh and continue
      refreshLine()
      continue
    
    case key:
    # Enter - accept line
    of ord(KeyEnter), ord(KeyEnter2):
      stdout.write("\n")
      let line = gState.buf
      if line.len > 0:
        addToHistory(line)
      return line
    
    # Ctrl+C - abort
    of ctrlKey('C'):
      stdout.write("\n")
      quit(1)
    
    # Ctrl+D - EOF if empty, else delete char
    of ctrlKey('D'):
      if gState.buf.len == 0:
        stdout.write("\n")
        return ""
      else:
        if gState.pos < gState.buf.len:
          deleteChar(gState.pos)
          refreshLine()
    
    # Backspace
    of ord(KeyBackspace), ord(KeyDel2):
      if gState.pos > 0:
        deleteChar(gState.pos - 1)
        dec gState.pos
        refreshLine()
    
    # Delete
    of ord(KeyDelete):
      if gState.pos < gState.buf.len:
        deleteChar(gState.pos)
        refreshLine()
    
    # Left arrow
    of ord(KeyLeft):
      if gState.pos > 0:
        dec gState.pos
        refreshLine()
    
    # Right arrow
    of ord(KeyRight):
      if gState.pos < gState.buf.len:
        inc gState.pos
        refreshLine()
    
    # Up arrow - context-aware navigation (history vs multiline)
    of ord(KeyUp):
      if gState.enableHistory:
        let promptLen = gState.prompt.len
        let currentTotalChars = promptLen + gState.pos
        let currentLine = if gState.cols > 0: currentTotalChars div gState.cols else: 0
        let totalLines = if gState.cols > 0: max(1, (promptLen + gState.buf.len + gState.cols - 1) div gState.cols) else: 1
        
        # If we're on the first line of input or single line, navigate history
        if currentLine == 0 or totalLines == 1:
          if gState.historyPos > 0:
            dec gState.historyPos
            gState.buf = gState.history[gState.historyPos]
            gState.pos = gState.buf.len
            refreshLine()
        else:
          # Move cursor up one line within current input (multiline navigation)
          let currentCol = if gState.cols > 0: currentTotalChars mod gState.cols else: currentTotalChars
          let targetTotalChars = (currentLine - 1) * gState.cols + currentCol
          let newPos = targetTotalChars - promptLen
          gState.pos = max(0, min(newPos, gState.buf.len))
          refreshLine()
      else:
        # No history - just do multiline navigation
        let promptLen = gState.prompt.len
        let currentTotalChars = promptLen + gState.pos
        let currentLine = if gState.cols > 0: currentTotalChars div gState.cols else: 0
        let currentCol = if gState.cols > 0: currentTotalChars mod gState.cols else: currentTotalChars
        
        if currentLine > 0:
          let targetTotalChars = (currentLine - 1) * gState.cols + currentCol
          let newPos = targetTotalChars - promptLen
          gState.pos = max(0, min(newPos, gState.buf.len))
          refreshLine()
    
    # Down arrow - context-aware navigation (history vs multiline)
    of ord(KeyDown):
      if gState.enableHistory:
        let promptLen = gState.prompt.len
        let currentTotalChars = promptLen + gState.pos
        let currentLine = if gState.cols > 0: currentTotalChars div gState.cols else: 0
        let totalLines = if gState.cols > 0: max(1, (promptLen + gState.buf.len + gState.cols - 1) div gState.cols) else: 1
        
        # If we're on the last line or cursor is at end, navigate history
        if currentLine == totalLines - 1 or gState.pos == gState.buf.len:
          if gState.historyPos < gState.history.len - 1:
            inc gState.historyPos
            gState.buf = gState.history[gState.historyPos]
            gState.pos = gState.buf.len
            refreshLine()
          elif gState.historyPos == gState.history.len - 1:
            inc gState.historyPos
            gState.buf = ""
            gState.pos = 0
            refreshLine()
        else:
          # Move cursor down one line within current input (multiline navigation)
          let currentCol = if gState.cols > 0: currentTotalChars mod gState.cols else: currentTotalChars
          let targetTotalChars = (currentLine + 1) * gState.cols + currentCol
          let newPos = targetTotalChars - promptLen
          gState.pos = max(0, min(newPos, gState.buf.len))
          refreshLine()
      else:
        # No history - just do multiline navigation
        let promptLen = gState.prompt.len
        let currentTotalChars = promptLen + gState.pos
        let currentLine = if gState.cols > 0: currentTotalChars div gState.cols else: 0
        let currentCol = if gState.cols > 0: currentTotalChars mod gState.cols else: currentTotalChars
        let totalLines = if gState.cols > 0: max(1, (promptLen + gState.buf.len + gState.cols - 1) div gState.cols) else: 1
        
        if currentLine < totalLines - 1:
          let targetTotalChars = (currentLine + 1) * gState.cols + currentCol
          let newPos = targetTotalChars - promptLen
          gState.pos = max(0, min(newPos, gState.buf.len))
          refreshLine()
    
    # Home
    of ord(KeyHome):
      gState.pos = 0
      refreshLine()
    
    # End
    of ord(KeyEnd):
      gState.pos = gState.buf.len
      refreshLine()
    
    # Clear screen
    of ctrlKey('L'):
      clearScreen()
      refreshLine()
    
    # Regular character input
    else:
      if key >= 32 and key <= 126:  # Printable ASCII
        insertChar(char(key), gState.pos)
        inc gState.pos
        refreshLine()

## Callback registration functions
proc registerCustomKeyCallback*(callback: CustomKeyCallback) =
  ## Register custom key callback that gets called before normal key processing
  gState.customKeyCallback = callback

proc registerHistoryLoadCallback*(callback: HistoryLoadCallback) =
  ## Register custom history load callback
  gState.historyLoadCallback = callback

proc registerHistorySaveCallback*(callback: HistorySaveCallback) =
  ## Register custom history save callback
  gState.historySaveCallback = callback

proc initLinecross*(enableHistory: bool = true) =
  ## Initialize linecross2 with optional feature flags
  gState = LinecrossState()
  
  # Initialize history system
  gState.enableHistory = enableHistory
  gState.history = @[]
  gState.historyPos = 0
  gState.maxHistoryLines = DefaultHistoryMaxLines
  
  # Initialize colors
  gState.promptColor = fgDefault
  gState.promptStyle = {}
  
  # Callbacks default to nil