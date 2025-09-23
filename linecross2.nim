## Linecross2 - Simplified Cross-platform Readline Replacement
## 
## A minimal readline implementation focusing on basic editing functionality.
## Features:
## - Basic cursor movement (left/right, home/end)
## - Character insertion and deletion
## - Multiline editing with simple full-redraw approach
## - Essential keyboard shortcuts only

import std/[terminal, strutils, strformat]

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

## Simple state for readline
type
  LinecrossState = object
    buf: string      # Input buffer
    pos: int         # Cursor position in buffer
    prompt: string   # Current prompt
    cols: int        # Terminal width
    lastBufferSize: int  # Track buffer size for clearing

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
  stdout.write(gState.prompt)
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
  stdout.write(gState.prompt)
  
  # Initial refresh (just positions cursor correctly)
  refreshLine()
  
  while true:
    let key = getKey()
    
    case key:
    # Enter - accept line
    of ord(KeyEnter), ord(KeyEnter2):
      stdout.write("\n")
      return gState.buf
    
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
    
    # Up arrow - move cursor up one line while preserving column
    of ord(KeyUp):
      let promptLen = gState.prompt.len
      let currentTotalChars = promptLen + gState.pos
      let currentLine = if gState.cols > 0: currentTotalChars div gState.cols else: 0
      let currentCol = if gState.cols > 0: currentTotalChars mod gState.cols else: currentTotalChars
      
      if currentLine > 0:
        # Calculate position one line up with same column
        let targetTotalChars = (currentLine - 1) * gState.cols + currentCol
        let newPos = targetTotalChars - promptLen
        # Ensure we don't go beyond buffer boundaries
        gState.pos = max(0, min(newPos, gState.buf.len))
        refreshLine()
    
    # Down arrow - move cursor down one line while preserving column
    of ord(KeyDown):
      let promptLen = gState.prompt.len
      let currentTotalChars = promptLen + gState.pos
      let currentLine = if gState.cols > 0: currentTotalChars div gState.cols else: 0
      let currentCol = if gState.cols > 0: currentTotalChars mod gState.cols else: currentTotalChars
      let totalLines = if gState.cols > 0: max(1, (promptLen + gState.buf.len + gState.cols - 1) div gState.cols) else: 1
      
      if currentLine < totalLines - 1:
        # Calculate position one line down with same column
        let targetTotalChars = (currentLine + 1) * gState.cols + currentCol
        let newPos = targetTotalChars - promptLen
        # Ensure we don't go beyond buffer boundaries
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

proc initLinecross*() =
  ## Initialize linecross2 - minimal setup required
  gState = LinecrossState()