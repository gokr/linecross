## Crossline - A cross-platform readline replacement for Nim
## 
## This is a Nim port of the Crossline library, providing a small, self-contained,
## zero-config, cross-platform readline replacement.
##
## Features:
## - Cross-platform support (Windows, Linux, Unix, macOS)
## - Rich set of editing shortcuts (79 shortcuts, 40 functions)
## - History management with search capabilities
## - Autocomplete support
## - Color text support using std/terminal
## - Paging and cursor control APIs
## - Multiple line editing mode
## - No external dependencies

import std/[os, strutils, sequtils, terminal, strformat]

# Optional system clipboard integration
when defined(useSystemClipboard):
  try:
    import nimclipboard
    const hasSystemClipboard = true
  except ImportError:
    echo "Warning: nimclipboard not available, using internal clipboard only"
    const hasSystemClipboard = false
else:
  const hasSystemClipboard = false

# Platform-specific imports handled by terminal module

## Constants
const
  # Default word delimiters for move and cut operations
  DefaultDelimiter* = " !\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~"
  
  # Configuration constants
  HistoryMaxLines* = 256
  HistoryBufLen* = 4096
  HistoryMatchPatternNum* = 16
  
  CompletionMaxLines* = 1024
  CompletionWordLen* = 64
  CompletionHelpLen* = 256
  CompletionHintLen* = 128

## Key codes for special keys
type
  KeyCode* = enum
    KeyTab = 9
    KeyBackspace = 8
    KeyEnter = 13
    KeyEnter2 = 10  # Windows vs Linux difference
    KeyEscape = 27
    KeyDel2 = 127   # Treated as Backspace in Linux
    
    # Function keys
    KeyF1 = 0x1000
    KeyF2 = 0x1001
    KeyF3 = 0x1002
    KeyF4 = 0x1003
    KeyF12 = 0x100B
    
    # Arrow keys
    KeyUp = 0x2000
    KeyDown = 0x2001
    KeyLeft = 0x2002
    KeyRight = 0x2003
    
    # Special keys
    KeyHome = 0x3000
    KeyEnd = 0x3001
    KeyPageUp = 0x3002
    KeyPageDown = 0x3003
    KeyInsert = 0x3004
    KeyDelete = 0x3005

## Completion system types
type
  CompletionItem* = object
    word*: string
    help*: string
    wordColor*: ForegroundColor
    helpColor*: ForegroundColor
    wordStyle*: set[Style]
    helpStyle*: set[Style]

  Completions* = object
    items*: seq[CompletionItem]
    hints*: string
    hintsColor*: ForegroundColor
    hintsStyle*: set[Style]

  CompletionCallback* = proc(buf: string, completions: var Completions) {.nimcall.}

## History system types  
type
  HistoryEntry* = object
    line*: string
    
  History* = object
    entries*: seq[HistoryEntry]
    current*: int
    maxLines*: int

  # History provider callbacks (optional)
  HistoryLoadCallback* = proc(): seq[HistoryEntry] {.nimcall.}
  HistorySaveCallback* = proc(entries: seq[HistoryEntry]): bool {.nimcall.}
  HistoryLookupCallback* = proc(pattern: string, maxResults: int): seq[HistoryEntry] {.nimcall.}

## Feature flags for extended shortcuts
type
  ExtendedFeatures* = object
    wordMovement*: bool      # Alt-B/F, Ctrl-Left/Right for word navigation
    textTransform*: bool     # Alt-U/L/C for case changes
    advancedCutPaste*: bool  # Alt-D, Alt-Backspace, Ctrl-X, Ctrl-Y/V
    multilineNav*: bool      # Ctrl-Up/Down for multi-line navigation  
    historySearch*: bool     # Ctrl-R, F4 for interactive history search
    helpSystem*: bool        # F1 help, Ctrl-^ debug mode
    advancedEdit*: bool      # Ctrl-T transpose, Alt-\ whitespace cleanup

## Predefined feature sets
const
  BasicFeatures* = ExtendedFeatures()  # All false - current basic implementation
  
  EssentialFeatures* = ExtendedFeatures(
    wordMovement: true,
    advancedCutPaste: true
  )
  
  StandardFeatures* = ExtendedFeatures(
    wordMovement: true, 
    textTransform: true,
    advancedCutPaste: true,
    multilineNav: true
  )
  
  FullFeatures* = ExtendedFeatures(
    wordMovement: true,
    textTransform: true, 
    advancedCutPaste: true,
    multilineNav: true,
    historySearch: true,
    helpSystem: true,
    advancedEdit: true
  )

## Main crossline state
type
  CrosslineState* = object
    # Terminal state
    isWindows*: bool

    # Input buffer and cursor
    buf*: string
    pos*: int  # cursor position in buffer
    prompt*: string

    # Display state
    promptLen*: int
    cols*: int
    rows*: int

    # Configuration
    delimiter*: string
    promptColor*: ForegroundColor
    promptStyle*: set[Style]
    features*: ExtendedFeatures  # Feature flags

    # History
    history*: History
    historyPos*: int
    searchMode*: bool
    searchPattern*: string
    historySaveCallback*: HistorySaveCallback
    historyLookupCallback*: HistoryLookupCallback

    # Completion
    completionCallback*: CompletionCallback
    completions*: Completions

    # Multi-line support
    multiLine*: bool
    lines*: seq[string]
    currentLine*: int

    # Paging
    pagingEnabled*: bool
    pageRows*: int
    
    # Clipboard for cut/paste operations
    clipBoard*: string

# Global state instance
var gState: CrosslineState

## Helper templates for control keys and special key combinations
template ctrlKey*(key: char): int = ord(key) - 0x40
template altKey*(key: int): int = key + ((ord(KeyEscape) + 1) shl 8)

## Extended Alt key constants (matching C implementation approach)
const
  AltB* = ord('b') + ((ord(KeyEscape) + 1) shl 8)     # Alt-B: Move back word
  AltF* = ord('f') + ((ord(KeyEscape) + 1) shl 8)     # Alt-F: Move forward word  
  AltU* = ord('u') + ((ord(KeyEscape) + 1) shl 8)     # Alt-U: Uppercase word
  AltL* = ord('l') + ((ord(KeyEscape) + 1) shl 8)     # Alt-L: Lowercase word
  AltC* = ord('c') + ((ord(KeyEscape) + 1) shl 8)     # Alt-C: Capitalize word
  AltD* = ord('d') + ((ord(KeyEscape) + 1) shl 8)     # Alt-D: Cut word forward
  AltBackspace* = ord(KeyBackspace) + ((ord(KeyEscape) + 1) shl 8)  # Alt-Backspace: Cut word back

## Low-level terminal I/O functions
proc enableRawMode*(): bool =
  ## Enable raw terminal mode for character-by-character input
  # Using terminal module's built-in functionality
  return true

proc disableRawMode*() =
  ## Restore original terminal mode  
  try:
    resetAttributes()
  except:
    discard

proc getChar*(): int =
  ## Read a single character from stdin without echo
  try:
    let ch = getch()
    return ord(ch)
  except:
    return -1

proc getScreenSize*(): (int, int) =
  ## Get terminal screen size (rows, cols)
  try:
    let (w, h) = terminalSize()
    return (h, w)
  except:
    return (25, 80)  # fallback

proc getCursorPos*(): (int, int) =
  ## Get current cursor position (row, col) - 0-based
  try:
    let (x, y) = terminal.getCursorPos()
    return (y, x)  # Convert from (x, y) to (row, col)
  except:
    return (0, 0)

proc setCursorPos*(row, col: int) =
  ## Set cursor position (0-based)
  try:
    terminal.setCursorPos(col, row)  # terminal module uses (x, y) order
  except:
    # Fallback using ANSI codes
    stdout.write(&"\x1b[{row + 1};{col + 1}H")
    stdout.flushFile()

proc moveCursor*(rowOffset, colOffset: int) =
  ## Move cursor by offset
  let (row, col) = getCursorPos()
  setCursorPos(row + rowOffset, col + colOffset)

proc clearScreen*() =
  ## Clear the entire screen
  try:
    eraseScreen()
    setCursorPos(0, 0)
  except:
    # Fallback
    stdout.write("\x1b[2J\x1b[H")
    stdout.flushFile()

proc hideCursor*(hide: bool) =
  ## Hide or show cursor
  try:
    if hide:
      terminal.hideCursor()
    else:
      terminal.showCursor()
  except:
    # Fallback using ANSI codes
    if hide:
      stdout.write("\x1b[?25l")
    else:
      stdout.write("\x1b[?25h")
    stdout.flushFile()

## Color functions using std/terminal
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
    # Fallback to ANSI codes. Emit reset for default, otherwise map common colors.
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

## Key sequence parsing and handling
proc parseEscapeSequence*(): int =
  ## Parse ANSI escape sequences for special keys
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
    of ord('2'):
      let ch3 = getChar()
      if ch3 == ord('~'):
        return ord(KeyInsert)
    of ord('3'):
      let ch3 = getChar()
      if ch3 == ord('~'):
        return ord(KeyDelete)
    of ord('4'):
      let ch3 = getChar()
      if ch3 == ord('~'):
        return ord(KeyEnd)
    of ord('5'):
      let ch3 = getChar()
      if ch3 == ord('~'):
        return ord(KeyPageUp)
    of ord('6'):
      let ch3 = getChar()
      if ch3 == ord('~'):
        return ord(KeyPageDown)
    else:
      discard
  elif ch1 == ord('O'):
    let ch2 = getChar()
    case ch2:
    of ord('P'): return ord(KeyF1)
    of ord('Q'): return ord(KeyF2)
    of ord('R'): return ord(KeyF3)
    of ord('S'): return ord(KeyF4)
    else: discard
  
  return ch1

proc getKey*(): int =
  ## Get a key press, handling escape sequences including Alt combinations
  let ch = getChar()
  if ch == ord(KeyEscape):
    # Use the enhanced parsing that handles Alt combinations
    let ch1 = getChar()
    if ch1 == -1:
      return ord(KeyEscape)
    
    # Check for Alt+letter combinations (ESC followed by letter)
    if ch1 >= ord('a') and ch1 <= ord('z'):
      return ch1 + ((ord(KeyEscape) + 1) shl 8)  # Alt+letter
    elif ch1 >= ord('A') and ch1 <= ord('Z'):
      return (ch1 + 32) + ((ord(KeyEscape) + 1) shl 8)  # Alt+Letter -> Alt+letter
    elif ch1 == ord(KeyBackspace):
      return AltBackspace
    
    # Fall back to standard escape sequence parsing
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
      of ord('2'):
        let ch3 = getChar()
        if ch3 == ord('~'):
          return ord(KeyInsert)
      of ord('3'):
        let ch3 = getChar()
        if ch3 == ord('~'):
          return ord(KeyDelete)
      of ord('4'):
        let ch3 = getChar()
        if ch3 == ord('~'):
          return ord(KeyEnd)
      of ord('5'):
        let ch3 = getChar()
        if ch3 == ord('~'):
          return ord(KeyPageUp)
      of ord('6'):
        let ch3 = getChar()
        if ch3 == ord('~'):
          return ord(KeyPageDown)
      else:
        discard
    elif ch1 == ord('O'):
      let ch2 = getChar()
      case ch2:
      of ord('P'): return ord(KeyF1)
      of ord('Q'): return ord(KeyF2)
      of ord('R'): return ord(KeyF3)
      of ord('S'): return ord(KeyF4)
      else: discard
    
    return ch1
  else:
    return ch

## History management functions
proc addToHistory*(line: string) =
  ## Add a line to history
  if line.len == 0:
    return
  
  # Remove duplicates
  gState.history.entries = gState.history.entries.filterIt(it.line != line)
  
  # Add to end
  gState.history.entries.add(HistoryEntry(line: line))
  
  # Trim if too many entries
  if gState.history.entries.len > gState.history.maxLines:
    gState.history.entries = gState.history.entries[^gState.history.maxLines..^1]

proc saveHistory*(filename: string): bool =
  ## Save history to file
  # If a user-provided save callback is registered, use it.
  if gState.historySaveCallback != nil:
    return gState.historySaveCallback(gState.history.entries)

  try:
    let file = open(filename, fmWrite)
    defer: file.close()

    for entry in gState.history.entries:
      file.writeLine(entry.line)

    return true
  except:
    return false

proc loadHistory*(filename: string): bool =
  ## Load history from file
  try:
    if not fileExists(filename):
      return true

    let file = open(filename, fmRead)
    defer: file.close()

    gState.history.entries = @[]
    for line in file.lines:
      if line.len > 0:
        gState.history.entries.add(HistoryEntry(line: line))

    return true
  except:
    return false

proc clearHistory*() =
  ## Clear all history
  gState.history.entries = @[]

proc lookupHistory*(pattern: string, maxResults: int = HistoryMatchPatternNum): seq[HistoryEntry] =
  ## Lookup history entries matching pattern. If a user callback is registered
  ## it will be used; otherwise we fall back to a simple in-memory filter.
  if gState.historyLookupCallback != nil:
    return gState.historyLookupCallback(pattern, maxResults)

  var results: seq[HistoryEntry] = @[]
  if pattern.len == 0:
    return gState.history.entries

  for entry in gState.history.entries:
    if entry.line.contains(pattern):
      results.add(entry)
      if results.len >= maxResults:
        break

  return results

## Buffer editing functions
proc insertChar*(ch: char, pos: int) =
  ## Insert character at position
  if pos <= gState.buf.len:
    gState.buf.insert($ch, pos)

proc deleteChar*(pos: int) =
  ## Delete character at position
  if pos >= 0 and pos < gState.buf.len:
    gState.buf.delete(pos..pos)

proc moveToWordStart*(pos: int): int =
  ## Move cursor to start of current or previous word
  var newPos = pos
  
  # Skip whitespace
  while newPos > 0 and gState.buf[newPos - 1] in gState.delimiter:
    dec newPos
  
  # Skip word characters
  while newPos > 0 and gState.buf[newPos - 1] notin gState.delimiter:
    dec newPos
  
  return newPos

proc moveToWordEnd*(pos: int): int =
  ## Move cursor to end of current or next word
  var newPos = pos
  
  # Skip whitespace
  while newPos < gState.buf.len and gState.buf[newPos] in gState.delimiter:
    inc newPos
  
  # Skip word characters  
  while newPos < gState.buf.len and gState.buf[newPos] notin gState.delimiter:
    inc newPos
  
  return newPos

## Text transformation functions
proc uppercaseWord*(startPos: int): int =
  ## Uppercase current or following word, return new cursor position
  var pos = startPos
  
  # Skip whitespace
  while pos < gState.buf.len and gState.buf[pos] in gState.delimiter:
    inc pos
  
  # Uppercase word characters
  while pos < gState.buf.len and gState.buf[pos] notin gState.delimiter:
    gState.buf[pos] = gState.buf[pos].toUpperAscii
    inc pos
  
  return pos

proc lowercaseWord*(startPos: int): int =
  ## Lowercase current or following word, return new cursor position
  var pos = startPos
  
  # Skip whitespace
  while pos < gState.buf.len and gState.buf[pos] in gState.delimiter:
    inc pos
  
  # Lowercase word characters
  while pos < gState.buf.len and gState.buf[pos] notin gState.delimiter:
    gState.buf[pos] = gState.buf[pos].toLowerAscii
    inc pos
  
  return pos

proc capitalizeWord*(startPos: int): int =
  ## Capitalize current or following word, return new cursor position
  var pos = startPos
  
  # Skip whitespace
  while pos < gState.buf.len and gState.buf[pos] in gState.delimiter:
    inc pos
  
  # Capitalize first character
  if pos < gState.buf.len and gState.buf[pos] notin gState.delimiter:
    gState.buf[pos] = gState.buf[pos].toUpperAscii
    inc pos
    
    # Lowercase remaining characters
    while pos < gState.buf.len and gState.buf[pos] notin gState.delimiter:
      gState.buf[pos] = gState.buf[pos].toLowerAscii
      inc pos
  
  return pos

## Cut/paste helper functions with optional system clipboard support
proc cutText*(startPos, endPos: int) =
  ## Cut text from startPos to endPos and store in clipboard
  if startPos >= 0 and endPos <= gState.buf.len and startPos <= endPos:
    let cutContent = gState.buf[startPos..<endPos]
    gState.clipBoard = cutContent
    gState.buf.delete(startPos..<endPos)
    
    # Also copy to system clipboard if available
    when defined(useSystemClipboard) and hasSystemClipboard:
      try:
        nimclipboard.setClipboardText(cutContent)
      except:
        discard  # Fall back to internal clipboard only

proc pasteText*(pos: int): int =
  ## Paste clipboard content at position, return new cursor position
  var pasteContent = ""
  
  # Try system clipboard first if available
  when defined(useSystemClipboard) and hasSystemClipboard:
    try:
      pasteContent = nimclipboard.getClipboardText()
    except:
      pasteContent = gState.clipBoard  # Fall back to internal
  else:
    pasteContent = gState.clipBoard
  
  if pasteContent.len > 0:
    gState.buf.insert(pasteContent, pos)
    return pos + pasteContent.len
  return pos

proc copyToClipboard*(text: string) =
  ## Copy text to both internal and system clipboard
  gState.clipBoard = text
  when defined(useSystemClipboard) and hasSystemClipboard:
    try:
      nimclipboard.setClipboardText(text)
    except:
      discard

## Display functions
proc calculatePromptLen*(prompt: string): int =
  ## Calculate visible length of prompt (excluding ANSI codes)
  var len = 0
  var inEscape = false
  
  for ch in prompt:
    if ch == '\x1b':
      inEscape = true
    elif inEscape and ch == 'm':
      inEscape = false
    elif not inEscape:
      inc len
  
  return len

proc refreshLine*() =
  ## Refresh the current line display
  let promptLen = calculatePromptLen(gState.prompt)
  
  # Go to beginning of line
  stdout.write("\r")
  
  # Display prompt with color
  setTextColor(gState.promptColor, gState.promptStyle)
  stdout.write(gState.prompt)
  resetAttributes()
  
  # Display buffer
  stdout.write(gState.buf)
  
  # Clear rest of line
  stdout.write("\x1b[K")
  
  # Position cursor at correct column (0-based indexing)
  let cursorCol = promptLen + gState.pos
  # Option A: Relative positioning from start of line (fixes off-by-one error)
  stdout.write(&"\r\x1b[{cursorCol}C")
  # Option B: Use terminal module absolute positioning
  # terminal.setCursorPos(cursorCol, getCurrentRow())  
  # Option C: ANSI absolute column positioning  
  # stdout.write(&"\r\x1b[{cursorCol + 1}G")
  stdout.flushFile()

## Completion system
proc triggerCompletion*() =
  ## Trigger completion callback and show results
  if gState.completionCallback == nil:
    return
  
  gState.completions = Completions()
  gState.completionCallback(gState.buf, gState.completions)
  
  if gState.completions.items.len == 0:
    return
  
  if gState.completions.items.len == 1:
    # Single match - complete it
    let completion = gState.completions.items[0]
    let prefix = gState.buf.split(' ')[^1]
    if completion.word.startsWith(prefix):
      let remaining = completion.word[prefix.len..^1]
      for ch in remaining:
        insertChar(ch, gState.pos)
        inc gState.pos
      refreshLine()
  else:
    # Multiple matches - show them
    stdout.write("\n")
    for item in gState.completions.items:
      setTextColor(item.wordColor, item.wordStyle)
      stdout.write(item.word)
      resetAttributes()
      
      if item.help.len > 0:
        stdout.write("  ")
        setTextColor(item.helpColor, item.helpStyle)
        stdout.write(item.help)
        resetAttributes()
      
      stdout.write("\n")
    
    refreshLine()

## Main readline implementation
proc readline*(prompt: string, initialText: string = ""): string =
  ## Main readline function
  if not enableRawMode():
    raise newException(IOError, "Failed to enable raw mode")
  
  defer: disableRawMode()
  
  gState.buf = initialText
  gState.pos = initialText.len
  gState.prompt = prompt
  gState.promptLen = calculatePromptLen(prompt)
  gState.historyPos = gState.history.entries.len
  
  refreshLine()
  
  while true:
    let key = getKey()
    
    case key:
    # Enter - accept line
    of ord(KeyEnter), ord(KeyEnter2):
      stdout.write("\n")
      let line = gState.buf
      if line.len > 0:
        addToHistory(line)
      return line
    
    # Ctrl+C - abort
    of ctrlKey('C'), ctrlKey('G'):
      stdout.write("\n")
      disableRawMode()
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
    of ord(KeyBackspace), ord(KeyDel2):  # KeyBackspace (8) and Ctrl+H are the same
      if gState.pos > 0:
        dec gState.pos
        deleteChar(gState.pos)
        refreshLine()
    
    # Delete
    of ord(KeyDelete):
      if gState.pos < gState.buf.len:
        deleteChar(gState.pos)
        refreshLine()
    
    # Movement keys
    of ord(KeyLeft), ctrlKey('B'):
      if gState.pos > 0:
        dec gState.pos
        refreshLine()
    
    of ord(KeyRight), ctrlKey('F'):
      if gState.pos < gState.buf.len:
        inc gState.pos
        refreshLine()
    
    of ord(KeyHome), ctrlKey('A'):
      gState.pos = 0
      refreshLine()
    
    of ord(KeyEnd), ctrlKey('E'):
      gState.pos = gState.buf.len
      refreshLine()
    
    # Word movement (fix existing Ctrl-W behavior)
    of ctrlKey('W'):  # Cut to left till whitespace 
      if gState.features.advancedCutPaste:
        # C-like behavior: cut to whitespace (not word)
        var cutStart = gState.pos
        while cutStart > 0 and gState.buf[cutStart - 1] != ' ':
          dec cutStart
        cutText(cutStart, gState.pos)
        gState.pos = cutStart
        refreshLine()
      else:
        # Legacy Nim behavior: move to word start
        gState.pos = moveToWordStart(gState.pos)
        refreshLine()
    
    # History navigation
    of ord(KeyUp), ctrlKey('P'):
      if gState.historyPos > 0:
        dec gState.historyPos
        gState.buf = gState.history.entries[gState.historyPos].line
        gState.pos = gState.buf.len
        refreshLine()
    
    of ord(KeyDown), ctrlKey('N'):
      if gState.historyPos < gState.history.entries.len - 1:
        inc gState.historyPos
        gState.buf = gState.history.entries[gState.historyPos].line
        gState.pos = gState.buf.len
        refreshLine()
      elif gState.historyPos == gState.history.entries.len - 1:
        inc gState.historyPos
        gState.buf = ""
        gState.pos = 0
        refreshLine()
    
    # Tab completion
    of ord(KeyTab):  # Tab key (9) and Ctrl+I are the same
      triggerCompletion()
    
    # Clear screen
    of ctrlKey('L'):
      clearScreen()
      refreshLine()
    
    # Kill line
    of ctrlKey('K'):  # Kill to end of line
      gState.buf = gState.buf[0..<gState.pos]
      refreshLine()
    
    of ctrlKey('U'):  # Kill to beginning of line
      gState.buf = gState.buf[gState.pos..^1]
      gState.pos = 0
      refreshLine()
    
    # Extended shortcuts - Word Movement
    of AltB:  # Alt-B: Move back word
      if gState.features.wordMovement:
        gState.pos = moveToWordStart(gState.pos)
        refreshLine()
    
    of AltF:  # Alt-F: Move forward word
      if gState.features.wordMovement:
        gState.pos = moveToWordEnd(gState.pos)
        refreshLine()
    
    # Extended shortcuts - Text Transformation  
    of AltU:  # Alt-U: Uppercase word
      if gState.features.textTransform:
        gState.pos = uppercaseWord(gState.pos)
        refreshLine()
    
    of AltL:  # Alt-L: Lowercase word
      if gState.features.textTransform:
        gState.pos = lowercaseWord(gState.pos)
        refreshLine()
    
    of AltC:  # Alt-C: Capitalize word
      if gState.features.textTransform:
        gState.pos = capitalizeWord(gState.pos)
        refreshLine()
    
    # Extended shortcuts - Advanced Cut/Paste
    of ctrlKey('X'):  # Ctrl-X: Cut line
      if gState.features.advancedCutPaste:
        cutText(0, gState.buf.len)
        gState.pos = 0
        refreshLine()
    
    of ctrlKey('Y'):  # Ctrl-Y: Paste
      if gState.features.advancedCutPaste:
        gState.pos = pasteText(gState.pos)
        refreshLine()
    
    of ctrlKey('V'):  # Ctrl-V: Alternative paste
      if gState.features.advancedCutPaste:
        gState.pos = pasteText(gState.pos)  
        refreshLine()
    
    of AltD:  # Alt-D: Cut word forward
      if gState.features.advancedCutPaste:
        let endPos = moveToWordEnd(gState.pos)
        cutText(gState.pos, endPos)
        refreshLine()
    
    of AltBackspace:  # Alt-Backspace: Cut word backward
      if gState.features.advancedCutPaste:
        let startPos = moveToWordStart(gState.pos)
        cutText(startPos, gState.pos)
        gState.pos = startPos
        refreshLine()
    
    # Extended shortcuts - Advanced Editing
    of ctrlKey('T'):  # Ctrl-T: Transpose characters
      if gState.features.advancedEdit:
        if gState.pos > 0 and gState.pos < gState.buf.len:
          let temp = gState.buf[gState.pos]
          gState.buf[gState.pos] = gState.buf[gState.pos - 1]
          gState.buf[gState.pos - 1] = temp
          if gState.pos < gState.buf.len - 1:
            inc gState.pos
          refreshLine()
    
    # Regular character input
    else:
      if key >= 32 and key <= 126:  # Printable ASCII
        insertChar(char(key), gState.pos)
        inc gState.pos
        refreshLine()

## Public API functions
proc setDelimiter*(delim: string) =
  ## Set word delimiters for movement and editing
  gState.delimiter = delim

proc setExtendedFeatures*(features: ExtendedFeatures) =
  ## Configure which extended shortcut features are enabled
  gState.features = features

proc enableFeature*(feature: string, enable: bool = true) =
  ## Enable or disable a specific feature by name
  case feature.toLowerAscii:
  of "wordmovement", "word": gState.features.wordMovement = enable
  of "texttransform", "text": gState.features.textTransform = enable
  of "advancedcutpaste", "cutpaste": gState.features.advancedCutPaste = enable
  of "multiline", "multilineNav": gState.features.multilineNav = enable
  of "historysearch", "history": gState.features.historySearch = enable
  of "helpsystem", "help": gState.features.helpSystem = enable
  of "advancededit", "edit": gState.features.advancedEdit = enable
  else:
    echo "Warning: Unknown feature: " & feature

proc getExtendedFeatures*(): ExtendedFeatures =
  ## Get current extended feature configuration
  return gState.features

proc registerCompletionCallback*(callback: CompletionCallback) =
  ## Register completion callback
  gState.completionCallback = callback

proc addCompletion*(completions: var Completions, word: string, help: string = "",
                   wordColor: ForegroundColor = fgDefault, helpColor: ForegroundColor = fgDefault,
                   wordStyle: set[Style] = {}, helpStyle: set[Style] = {}) =
  ## Add completion item
  completions.items.add(CompletionItem(
    word: word, 
    help: help, 
    wordColor: wordColor, 
    helpColor: helpColor,
    wordStyle: wordStyle,
    helpStyle: helpStyle
  ))

proc setHints*(completions: var Completions, hints: string,
              color: ForegroundColor = fgDefault, style: set[Style] = {}) =
  ## Set completion hints
  completions.hints = hints
  completions.hintsColor = color
  completions.hintsStyle = style

## Paging support
proc enablePaging*(enable: bool) =
  ## Enable or disable paging
  gState.pagingEnabled = enable

proc checkPaging*(lineCount: int = 1): bool =
  ## Check if paging should pause, returns true if user wants to quit
  if not gState.pagingEnabled:
    return false
  
  gState.pageRows += lineCount
  if gState.pageRows >= gState.rows - 1:
    stdout.write("*** Press <Space> or <Enter> to continue . . .")
    stdout.flushFile()
    
    let key = getKey()
    stdout.write("\r\x1b[K")  # Clear the paging prompt
    
    gState.pageRows = 0
    return key == ctrlKey('C') or key == ord('q')
  
  return false

## Initialize the crossline state
proc initCrossline*(features: ExtendedFeatures = BasicFeatures) =
  ## Initialize crossline with optional extended features
  gState = CrosslineState()
  gState.isWindows = defined(windows)
  gState.delimiter = DefaultDelimiter
  gState.history = History(maxLines: HistoryMaxLines)
  gState.promptColor = fgDefault
  gState.promptStyle = {}
  gState.pagingEnabled = false
  gState.features = features
  gState.clipBoard = ""
  
  # Get initial screen size
  let (rows, cols) = getScreenSize()
  gState.rows = rows
  gState.cols = cols

# Initialize on module load
initCrossline()