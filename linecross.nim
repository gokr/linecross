## Linecross - A cross-platform readline replacement for Nim
## 
## This is a Nim port of the Linecross library, providing a small, self-contained,
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

import std/[terminal, strutils, os, exitprocs, strformat, sequtils]

# Platform-specific imports
when defined(posix):
  import std/posix

# Optional system clipboard integration
when defined(useSystemClipboard):
  import libclip/clipboard

# Platform-specific imports handled by terminal module

## Constants
const
  # Default word delimiters for move and cut operations
  DefaultDelimiter* = " !\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~"
  
  # Default configuration values (Nim uses dynamic containers, so these are just defaults)
  DefaultHistoryMaxLines* = 256
  DefaultHistoryMaxMatches* = 40

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
  History* = object
    entries*: seq[string]
    current*: int
    maxLines*: int

  # History provider callbacks (optional)
  HistoryLoadCallback* = proc(): seq[string] {.nimcall.}
  HistorySaveCallback* = proc(entries: seq[string]): bool {.nimcall.}
  HistoryLookupCallback* = proc(pattern: string, maxResults: int): seq[string] {.nimcall.}

## Function key and UI callbacks for pluggable screen output
type
  # Function key callbacks - all return strings to display to user
  HelpCallback* = proc(): string {.nimcall.}
  HistoryDisplayCallback* = proc(entries: seq[string]): string {.nimcall.}
  ClearHistoryCallback* = proc(): bool {.nimcall.}  # returns true if user confirms
  DebugCallback* = proc(keyCode: int): string {.nimcall.}
  
  # Search and completion callbacks
  HistorySearchCallback* = proc(pattern: string, reverse: bool): seq[string] {.nimcall.}
  CompletionListCallback* = proc(buf: string): string {.nimcall.}
  
  # Custom key combination callback - returns true if key was handled
  CustomKeyCallback* = proc(keyCode: int, buffer: string): bool {.nimcall.}
  
  # Enhanced display callbacks for persistent input area
  CompletionDisplayCallback* = proc(completions: Completions, prefix: string) {.nimcall.}
  CompletionClearCallback* = proc() {.nimcall.}
  
  # Output mode for persistent input area management
  OutputMode* = enum
    omNormal,     # Normal single-line input at bottom
    omPersistent  # Persistent input area with scrollable output above
  
  # Saved input state for restoration after output
  InputState* = object
    buffer*: string
    cursorPos*: int
    promptText*: string
    displayLines*: int  # How many lines the input currently occupies
  
  # Configuration for persistent mode
  PersistentModeConfig* = object
    inputAreaMaxHeight*: int      # Maximum lines for input area (default: 5)
    scrollableAreaMinHeight*: int # Minimum space for output (default: 10)
    enablePaging*: bool          # Enable automatic paging (default: true)
    pagingPrompt*: string        # Custom paging prompt
    reserveStatusLine*: bool     # Reserve line for status info (default: false)
  
  # Individual F-key and feature control
  FunctionKeyFeatures* = object
    f1Help*: bool             # F1 shows help
    f2History*: bool          # F2 shows history
    f3ClearHistory*: bool     # F3 clears history with confirmation
    f4HistorySearch*: bool    # F4 searches history with current input
    debugMode*: bool          # Ctrl-^ shows debug info

  # Enum for feature types (for type-safe feature enabling)
  FeatureType* = enum
    WordMovement
    TextTransform
    AdvancedCutPaste
    MultilineNav
    HistorySearch
    HelpSystem
    AdvancedEdit
    KeyVariants
    AdvancedControls

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
    functionKeys*: FunctionKeyFeatures  # Individual F-key control
    keyVariants*: bool       # ESC+, Ctrl+, Alt+ key sequence variants
    advancedControls*: bool  # Insert, Alt-\, Alt-R, Alt-=, etc.
    inPlaceCompletion*: bool # In-place completion display updates

## Predefined feature sets
const
  BasicFeatures* = ExtendedFeatures()  # All false - current basic implementation
  
  EssentialFeatures* = ExtendedFeatures(
    wordMovement: true,
    textTransform: false,
    advancedCutPaste: true,
    multilineNav: false,
    historySearch: false,
    helpSystem: false,
    advancedEdit: false,
    functionKeys: FunctionKeyFeatures(f1Help: false, f2History: false, f3ClearHistory: false, f4HistorySearch: false, debugMode: false),
    keyVariants: false,
    advancedControls: false,
    inPlaceCompletion: true  # Include in-place completion in essential features
  )
  
  StandardFeatures* = ExtendedFeatures(
    wordMovement: true, 
    textTransform: true,
    advancedCutPaste: true,
    multilineNav: true,
    historySearch: false,
    helpSystem: false,
    advancedEdit: false,
    functionKeys: FunctionKeyFeatures(f1Help: true, f2History: false, f3ClearHistory: false, f4HistorySearch: false, debugMode: false),  # Enable F1 help
    keyVariants: false,
    advancedControls: false
  )
  
  FullFeatures* = ExtendedFeatures(
    wordMovement: true,
    textTransform: true, 
    advancedCutPaste: true,
    multilineNav: true,
    historySearch: true,
    helpSystem: true,
    advancedEdit: true,
    keyVariants: true,
    advancedControls: true,
    inPlaceCompletion: true,
    functionKeys: FunctionKeyFeatures(  # Enable all function keys
      f1Help: true,
      f2History: true,
      f3ClearHistory: true,
      f4HistorySearch: true,
      debugMode: true
    )
  )

## Default persistent mode configuration
const
  DefaultPersistentConfig* = PersistentModeConfig(
    inputAreaMaxHeight: 5,
    scrollableAreaMinHeight: 10,
    enablePaging: true,
    pagingPrompt: "[More... Press any key to continue, 'q' to quit]",
    reserveStatusLine: false
  )

## Main linecross state
type
  LinecrossState* = object
    # Terminal state
    isWindows*: bool

    # Input buffer and cursor
    buf*: string
    pos*: int  # cursor position in buffer
    prompt*: string

    # Display state
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
    completionDisplayLines*: int  # Track lines used by completion display
    
    # Bash-like completion state
    bashCompletionWaiting*: bool    # True if we're waiting for second tab press
    bashCompletionPrefix*: string   # Prefix we were trying to complete
    bashCompletionMatches*: Completions  # Stored matches from first tab press

    # Function key and UI callbacks (optional - defaults provided if nil)
    helpCallback*: HelpCallback
    historyDisplayCallback*: HistoryDisplayCallback
    clearHistoryCallback*: ClearHistoryCallback
    debugCallback*: DebugCallback
    historySearchCallback*: HistorySearchCallback
    completionListCallback*: CompletionListCallback
    customKeyCallback*: CustomKeyCallback

    # Multi-line support
    multiLine*: bool
    lines*: seq[string]
    currentLine*: int

    # Paging
    pagingEnabled*: bool
    pageRows*: int
    
    # Clipboard for cut/paste operations
    clipBoard*: string

    # Enhanced display callbacks for persistent input area
    completionDisplayCallback*: CompletionDisplayCallback
    completionClearCallback*: CompletionClearCallback

    # Persistent input area management
    outputMode*: OutputMode           # Current display mode
    inputAreaHeight*: int             # Height of persistent input area (lines)
    inputAreaStartRow*: int           # Absolute row where input area begins  
    scrollableAreaHeight*: int        # Available space above input area
    savedInputState*: InputState      # Saved state for restoration
    persistentConfig*: PersistentModeConfig  # Configuration for persistent mode
    belowContentClearMs*: int         # Auto-clear timeout for content below input area

# Global state instance
var gState: LinecrossState

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
  
  # Additional Alt key constants for missing C implementation features
  AltR* = ord('r') + ((ord(KeyEscape) + 1) shl 8)     # Alt-R: Revert line
  AltBackslash* = ord('\\') + ((ord(KeyEscape) + 1) shl 8)  # Alt-\: Delete whitespace
  AltEquals* = ord('=') + ((ord(KeyEscape) + 1) shl 8)    # Alt-=: List completions
  AltQuestion* = ord('?') + ((ord(KeyEscape) + 1) shl 8)  # Alt-?: List completions
  AltLess* = ord('<') + ((ord(KeyEscape) + 1) shl 8)      # Alt-<: Move to first history
  AltGreater* = ord('>') + ((ord(KeyEscape) + 1) shl 8)   # Alt->: Move to last history

# Special key constant for Ctrl-^
const CtrlCaret* = 30  # Ctrl-^ (0x1E)

# Special key constant for Ctrl+Tab
const CtrlTab* = 0x00  # Ctrl+Tab generates 0x00 in most terminals

# Special key constant for Shift+Tab
const ShiftTab* = 91  # Standard Shift+Tab key code

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
    # Ensure we have sensible minimum values
    let rows = if h <= 0: 25 else: h
    let cols = if w <= 0: 80 else: w
    return (rows, cols)
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
    elif ch1 == ord('\\'):
      return AltBackslash
    elif ch1 == ord('='):
      return AltEquals
    elif ch1 == ord('?'):
      return AltQuestion
    elif ch1 == ord('<'):
      return AltLess
    elif ch1 == ord('>'):
      return AltGreater
    elif ch1 == ord('r'):
      return AltR
    elif ch1 == ord('d'):
      return AltD
    
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
        elif ch3 == ord(';'):
          # Enhanced parsing for Ctrl sequences like 1;5C (Ctrl-Right), 1;5D (Ctrl-Left) 
          let ch4 = getChar()
          if ch4 == ord('5'):  # Ctrl modifier
            let ch5 = getChar()
            case ch5:
            of ord('C'): return altKey(ord(KeyRight))  # Ctrl-Right as Alt-Right variant
            of ord('D'): return altKey(ord(KeyLeft))   # Ctrl-Left as Alt-Left variant
            of ord('A'): return altKey(ord(KeyUp))     # Ctrl-Up
            of ord('B'): return altKey(ord(KeyDown))   # Ctrl-Down
            else: discard
          elif ch4 == ord('3'):  # Alt modifier  
            let ch5 = getChar()
            case ch5:
            of ord('C'): return altKey(ord(KeyRight))  # Alt-Right
            of ord('D'): return altKey(ord(KeyLeft))   # Alt-Left
            of ord('A'): return altKey(ord(KeyUp))     # Alt-Up
            of ord('B'): return altKey(ord(KeyDown))   # Alt-Down
            else: discard
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
  gState.history.entries = gState.history.entries.filterIt(it != line)
  
  # Add to end
  gState.history.entries.add(line)
  
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
      file.writeLine(entry)

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
        gState.history.entries.add(line)

    return true
  except:
    return false

proc clearHistory*() =
  ## Clear all history
  gState.history.entries = @[]

proc lookupHistory*(pattern: string, maxResults: int = DefaultHistoryMaxMatches): seq[string] =
  ## Lookup history entries matching pattern. If a user callback is registered
  ## it will be used; otherwise we fall back to a simple in-memory filter.
  if gState.historyLookupCallback != nil:
    return gState.historyLookupCallback(pattern, maxResults)

  var results: seq[string] = @[]
  if pattern.len == 0:
    return gState.history.entries

  for entry in gState.history.entries:
    if entry.contains(pattern):
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
    when defined(useSystemClipboard):
      discard setClipboardText(cutContent)

proc pasteText*(pos: int): int =
  ## Paste clipboard content at position, return new cursor position
  var pasteContent = ""
  
  # Try system clipboard first if available
  when defined(useSystemClipboard):
    pasteContent = getClipboardText()
  else:
    pasteContent = gState.clipBoard
  
  if pasteContent.len > 0:
    gState.buf.insert(pasteContent, pos)
    return pos + pasteContent.len
  return pos

proc copyToClipboard*(text: string) =
  ## Copy text to both internal and system clipboard
  gState.clipBoard = text
  when defined(useSystemClipboard):
    discard setClipboardText(text)

## Display functions

## Multiline text calculation helpers
proc calculatePromptDisplayLength(): int =
  ## Calculate the display length of the prompt (excluding color codes)
  return gState.prompt.len

proc calculateWrappedPosition(bufPos: int): (int, int) =
  ## Calculate which screen line and column a buffer position corresponds to
  ## Returns (lineNum, colNum) where lineNum=0 is the first line
  let promptLen = calculatePromptDisplayLength()
  let totalCharsBeforeCursor = promptLen + bufPos
  let lineNum = totalCharsBeforeCursor div gState.cols
  let colNum = totalCharsBeforeCursor mod gState.cols
  return (lineNum, colNum)

proc calculateTotalLines(): int =
  ## Calculate total screen lines needed for current buffer
  let promptLen = calculatePromptDisplayLength()
  let totalChars = promptLen + gState.buf.len
  return max(1, (totalChars + gState.cols - 1) div gState.cols)

proc getPhysicalCursorPos(): (int, int) =
  ## Get current physical screen position of cursor
  return calculateWrappedPosition(gState.pos)

proc getCurrentLineInBuffer(): int =
  ## Get which wrapped line the cursor is currently on (0-based)
  let (lineNum, _) = calculateWrappedPosition(gState.pos)
  return lineNum

proc isAtStartOfLine(): bool =
  ## Check if cursor is at the start of a wrapped line
  let (_, colNum) = calculateWrappedPosition(gState.pos)
  let promptLen = calculatePromptDisplayLength()
  return colNum == 0 or (getCurrentLineInBuffer() == 0 and gState.pos == 0)

proc isAtEndOfLine(): bool =
  ## Check if cursor is at the end of a wrapped line
  let (lineNum, colNum) = calculateWrappedPosition(gState.pos)
  let totalLines = calculateTotalLines()
  # At end if we're on the last line and at the actual end of buffer
  return lineNum == totalLines - 1 and gState.pos == gState.buf.len

proc moveToLine(targetLine: int): int =
  ## Move cursor to start of specified wrapped line, return new buffer position
  if targetLine < 0:
    return 0
  
  let promptLen = calculatePromptDisplayLength()
  let targetPos = max(0, targetLine * gState.cols - promptLen)
  return min(targetPos, gState.buf.len)

proc findBufferPosForLineCol(lineNum: int, colNum: int): int =
  ## Find buffer position for given screen line and column
  let promptLen = calculatePromptDisplayLength()
  let totalPos = lineNum * gState.cols + colNum
  let bufPos = totalPos - promptLen
  return max(0, min(bufPos, gState.buf.len))

proc refreshPersistentInputArea() =
  ## Refresh display in persistent input area mode
  # Move to start of input area
  stdout.write(&"\x1b[{gState.inputAreaStartRow}H")
  
  # Clear the input area
  for i in 0..<gState.inputAreaHeight:
    stdout.write(&"\x1b[{gState.inputAreaStartRow + i}H")
    stdout.write("\x1b[K")  # Clear line
  
  # Move back to start of input area
  stdout.write(&"\x1b[{gState.inputAreaStartRow}H")
  
  # Display prompt with color
  setTextColor(gState.promptColor, gState.promptStyle)
  stdout.write(gState.prompt)
  resetAttributes()
  
  # Display the entire buffer
  stdout.write(gState.buf)
  
  # Calculate cursor position within the input area
  let promptLen = calculatePromptDisplayLength()
  let totalCharsBeforeCursor = promptLen + gState.pos
  let cursorLine = totalCharsBeforeCursor div gState.cols
  let cursorCol = totalCharsBeforeCursor mod gState.cols
  
  # Position cursor correctly within the input area
  let targetRow = gState.inputAreaStartRow + cursorLine
  stdout.write(&"\x1b[{targetRow}H")
  if cursorCol > 0:
    stdout.write(&"\x1b[{cursorCol}C")
  
  stdout.flushFile()

proc refreshNormalInputLine() =
  ## Refresh display in normal mode - proper multiline handling without repetition
  let promptLen = calculatePromptDisplayLength()
  let totalCharsBeforeCursor = promptLen + gState.pos
  let totalChars = promptLen + gState.buf.len
  let cursorLine = totalCharsBeforeCursor div gState.cols
  let cursorCol = totalCharsBeforeCursor mod gState.cols
  let totalLines = max(1, (totalChars + gState.cols - 1) div gState.cols)
  
  # First, move to the start of the first line if we're on a wrapped line
  if cursorLine > 0:
    stdout.write(&"\x1b[{cursorLine}A")  # Move up to first line
  
  # Go to start of line
  stdout.write("\r")
  
  # Clear all content that might be there (including wrapped lines)
  stdout.write("\x1b[0J")
  
  # Display prompt with color
  setTextColor(gState.promptColor, gState.promptStyle)
  stdout.write(gState.prompt)
  resetAttributes()
  
  # Display the entire buffer (let terminal handle natural wrapping)
  stdout.write(gState.buf)
  
  # Now position cursor correctly using absolute positioning
  # We're at the end of the buffer, need to move to cursor position
  let targetLine = cursorLine
  let targetCol = cursorCol
  
  # Use absolute positioning instead of relative character movement
  if totalLines > 1:
    # Multi-line case: go to first line, then move to target position
    stdout.write("\r")  # Go to start of current (last) line
    
    # Move up to first line
    if totalLines > 1:
      stdout.write(&"\x1b[{totalLines - 1}A")
    
    # Move down to target line
    if targetLine > 0:
      stdout.write(&"\x1b[{targetLine}B")
    
    # Move to target column
    if targetCol > 0:
      stdout.write(&"\x1b[{targetCol}C")
  else:
    # Single line case: simple positioning
    stdout.write("\r")
    if cursorCol > 0:
      stdout.write(&"\x1b[{cursorCol}C")
  
  stdout.flushFile()

proc refreshLine*() =
  ## Refresh the multiline-aware display
  if gState.outputMode == omPersistent:
    refreshPersistentInputArea()
  else:
    refreshNormalInputLine()

## Completion system
proc longestCommonPrefix(words: seq[string]): string =
  ## Calculate the longest common prefix among a sequence of words
  if words.len == 0:
    return ""
  if words.len == 1:
    return words[0]
  
  var commonPrefix = ""
  var minLen = words[0].len
  for word in words[1..^1]:
    if word.len < minLen:
      minLen = word.len
  
  for i in 0..<minLen:
    let ch = words[0][i]
    var allMatch = true
    for word in words[1..^1]:
      if word[i] != ch:
        allMatch = false
        break
    if allMatch:
      commonPrefix.add(ch)
    else:
      break
  
  return commonPrefix

proc clearDisplayBelowPrompt() =
  ## Clear any displayed lines below the prompt
  # Position cursor back at the prompt line at the current input position
  # Go to start of line, display prompt and buffer up to cursor position
  stdout.write("\r")
  setTextColor(gState.promptColor, gState.promptStyle)
  stdout.write(gState.prompt)
  resetAttributes()
  stdout.write(gState.buf[0..<gState.pos])
  # Clear from cursor to end of screen
  stdout.write("\x1b[0J")
  stdout.flushFile()

proc clearCompletionDisplay() =
  if gState.features.inPlaceCompletion and gState.completionDisplayLines > 0:
    clearDisplayBelowPrompt()
    gState.completionDisplayLines = 0
  # Reset bash completion state
  gState.bashCompletionWaiting = false
  gState.bashCompletionPrefix = ""

proc triggerCompletion*() =
  ## Trigger completion callback with bash-like behavior
  if gState.completionCallback == nil:
    return
  
  # Get current completion context
  let spacePos = gState.buf.rfind(' ')
  let wordStart = if spacePos == -1: 0 else: spacePos + 1
  let currentWord = gState.buf[wordStart..^1]
  let currentPrefix = if currentWord.startsWith("/") and currentWord.len > 1: currentWord[1..^1] else: currentWord
  
  # Check if this is a second consecutive tab with same prefix
  if gState.bashCompletionWaiting and gState.bashCompletionPrefix == currentPrefix:
    # Second tab - show the matches we stored from first tab
    clearCompletionDisplay()
    
    if gState.bashCompletionMatches.items.len > 0:
      stdout.write("\n")
      var lineCount = if gState.features.inPlaceCompletion: 1 else: 0
      
      for item in gState.bashCompletionMatches.items:
        setTextColor(item.wordColor, item.wordStyle)
        stdout.write(item.word)
        resetAttributes()
        
        if item.help.len > 0:
          stdout.write("  ")
          setTextColor(item.helpColor, item.helpStyle)
          stdout.write(item.help)
          resetAttributes()
        
        stdout.write("\n")
        if gState.features.inPlaceCompletion:
          inc lineCount
      
      if gState.features.inPlaceCompletion:
        gState.completionDisplayLines = lineCount
      
      # Position cursor at the current input position
      if lineCount > 0:
        stdout.write(&"\x1b[{lineCount}A")  # Move up to input line
      stdout.write("\r")  # Go to start of line
      setTextColor(gState.promptColor, gState.promptStyle)
      stdout.write(gState.prompt)
      resetAttributes()
      stdout.write(gState.buf[0..<gState.pos])  # Natural cursor positioning
      stdout.flushFile()
    
    # Reset bash completion state after showing matches
    gState.bashCompletionWaiting = false
    gState.bashCompletionPrefix = ""
    return
  
  # First tab or different prefix - get fresh completions
  gState.completions = Completions()
  gState.completionCallback(gState.buf, gState.completions)
  
  if gState.completions.items.len == 0:
    # No matches - clear any previous state
    clearCompletionDisplay()
    gState.bashCompletionWaiting = false
    gState.bashCompletionPrefix = ""
    return
  
  if gState.completions.items.len == 1:
    # Single match - complete it fully and add space (bash behavior)
    let completion = gState.completions.items[0]
    let rawPrefix = gState.buf.split(' ')[^1]
    let prefix = if rawPrefix.startsWith("/") and rawPrefix.len > 1: rawPrefix[1..^1] else: rawPrefix
    
    if completion.word.startsWith(prefix):
      let remaining = completion.word[prefix.len..^1]
      for ch in remaining:
        insertChar(ch, gState.pos)
        inc gState.pos
      # Add space after single completion (bash behavior)
      insertChar(' ', gState.pos)
      inc gState.pos
      refreshLine()
    
    # Clear bash completion state
    gState.bashCompletionWaiting = false
    gState.bashCompletionPrefix = ""
  else:
    # Multiple matches - first tab does nothing, just store matches
    gState.bashCompletionWaiting = true
    gState.bashCompletionPrefix = currentPrefix
    gState.bashCompletionMatches = gState.completions

## Default callback implementations (used when user callbacks are nil)
proc defaultHelpCallback(): string =
  ## Default help text showing available shortcuts
  var help = "Linecross Keyboard Shortcuts:\n\n"
  
  # Basic shortcuts (always available)
  help.add "Basic Movement:\n"
  help.add "  Left/Ctrl-B     - Move back a character\n"
  help.add "  Right/Ctrl-F    - Move forward a character\n" 
  help.add "  Home/Ctrl-A     - Move to start of line\n"
  help.add "  End/Ctrl-E      - Move to end of line\n\n"
  
  help.add "Editing:\n"
  help.add "  Backspace       - Delete character before cursor\n"
  help.add "  Delete/Ctrl-D   - Delete character under cursor\n"
  help.add "  Ctrl-K          - Cut to end of line\n"
  help.add "  Ctrl-U          - Cut to beginning of line\n\n"
  
  help.add "History & Control:\n"
  help.add "  Up/Ctrl-P       - Previous history\n"
  help.add "  Down/Ctrl-N     - Next history\n"
  help.add "  Tab             - Trigger completion\n"
  help.add "  Ctrl-L          - Clear screen\n"
  help.add "  Ctrl-C/Ctrl-G   - Exit\n"
  help.add "  Enter           - Accept line\n\n"
  
  # Extended shortcuts (feature dependent)
  if gState.features.wordMovement:
    help.add "Word Movement:\n"
    help.add "  Alt-B           - Move back one word\n"
    help.add "  Alt-F           - Move forward one word\n\n"
  
  if gState.features.textTransform:
    help.add "Text Transform:\n"
    help.add "  Alt-U           - Uppercase word\n"
    help.add "  Alt-L           - Lowercase word\n"
    help.add "  Alt-C           - Capitalize word\n\n"
  
  if gState.features.advancedCutPaste:
    help.add "Cut/Paste:\n"
    help.add "  Ctrl-X          - Cut entire line\n"
    help.add "  Ctrl-Y/Ctrl-V   - Paste from clipboard\n"
    help.add "  Alt-D           - Cut word forward\n"
    help.add "  Alt-Backspace   - Cut word backward\n\n"
  
  if gState.features.functionKeys.f2History:
    help.add "  F2              - Show history\n"
  if gState.features.functionKeys.f3ClearHistory:
    help.add "  F3              - Clear history\n"
  if gState.features.functionKeys.f4HistorySearch:
    help.add "  F4              - Search history\n"
  
  help.add "\nPress any key to continue..."
  return help

## Interactive history search implementation
proc performHistorySearch(reverse: bool) =
  ## Interactive history search with real-time pattern matching
  var searchPattern = ""
  var searchResults: seq[string] = @[]
  var currentIndex = 0
  
  # Save current state
  let originalBuf = gState.buf
  let originalPos = gState.pos
  
  while true:
    # Update search results based on current pattern
    if gState.historySearchCallback != nil:
      searchResults = gState.historySearchCallback(searchPattern, reverse)
    else:
      searchResults = lookupHistory(searchPattern)
    
    # Display search interface
    stdout.write("\r\x1b[K")  # Clear line
    let direction = if reverse: "reverse" else: "forward"
    stdout.write(&"({direction}-i-search)`{searchPattern}': ")
    
    if searchResults.len > 0 and currentIndex < searchResults.len:
      stdout.write(searchResults[currentIndex])
    else:
      stdout.write("(no matches)")
    
    stdout.flushFile()
    
    let key = getKey()
    
    case key:
    of ord(KeyEnter), ord(KeyEnter2):
      # Accept current match
      if searchResults.len > 0 and currentIndex < searchResults.len:
        gState.buf = searchResults[currentIndex]
        gState.pos = gState.buf.len
      break
      
    of ctrlKey('G'), ord(KeyEscape):
      # Cancel search - restore original
      gState.buf = originalBuf
      gState.pos = originalPos
      break
      
    of ctrlKey('R'):
      # Continue reverse search
      if reverse and currentIndex < searchResults.len - 1:
        inc currentIndex
      elif not reverse:
        # Switch to reverse search
        currentIndex = 0
        
    of ctrlKey('S'):
      # Continue forward search
      if not reverse and currentIndex < searchResults.len - 1:
        inc currentIndex
      elif reverse:
        # Switch to forward search
        currentIndex = 0
        
    of ord(KeyBackspace), ord(KeyDel2):
      # Remove character from search pattern
      if searchPattern.len > 0:
        searchPattern = searchPattern[0..^2]
        currentIndex = 0
        
    else:
      # Add character to search pattern
      if key >= 32 and key <= 126:
        searchPattern.add(char(key))
        currentIndex = 0
  
  stdout.write("\n")

proc defaultHistoryDisplayCallback(entries: seq[string]): string =
  ## Default history display showing recent entries with numbers
  var display = "Command History:\n"
  if entries.len == 0:
    display.add "  (empty)\n"
  else:
    let start = max(0, entries.len - 20)  # Show last 20 entries
    for i in start..<entries.len:
      display.add &"  {i + 1:3}: {entries[i]}\n"
  display.add "\nPress any key to continue..."
  return display

proc defaultClearHistoryCallback(): bool =
  ## Default history clear confirmation
  stdout.write("Clear all history? [y/N]: ")
  stdout.flushFile()
  let key = getKey()
  stdout.write("\n")
  return key == ord('y') or key == ord('Y')

proc defaultDebugCallback(keyCode: int): string =
  ## Default debug display showing key code information
  var debug = &"Key Debug Information:\n"
  debug.add &"  Raw key code: {keyCode} (0x{keyCode:X})\n"
  debug.add &"  Character: '{char(keyCode and 0xFF)}' (if printable)\n"
  
  if keyCode == ord(KeyEscape):
    debug.add "  Special: Escape key\n"
  elif keyCode >= ord(KeyF1) and keyCode <= ord(KeyF12):
    debug.add &"  Special: Function key F{keyCode - ord(KeyF1) + 1}\n"
  elif keyCode >= ord(KeyUp) and keyCode <= ord(KeyRight):
    let arrows = ["Up", "Down", "Left", "Right"]
    debug.add &"  Special: {arrows[keyCode - ord(KeyUp)]} arrow\n"
  elif keyCode >= 1 and keyCode <= 26:
    debug.add &"  Special: Ctrl+{char(keyCode + ord('A') - 1)}\n"
  elif (keyCode shr 8) == (ord(KeyEscape) + 1):
    let altChar = char(keyCode and 0xFF)
    debug.add &"  Special: Alt+{altChar}\n"
  
  debug.add "\nPress any key to continue..."
  return debug

proc setPrompt*(prompt: string) =
  gState.prompt = prompt

proc readline*(prompt: string, initialText: string = ""): string =
  ## Main readline function
  
  defer: resetAttributes()

  setPrompt(prompt)
  gState.buf = initialText
  gState.pos = initialText.len
  gState.historyPos = gState.history.entries.len
  
  refreshLine()
  
  while true:
    let key = getKey()
    #echo "KEY: " & $key
    # First custom key handling (mode switching, etc.)
    if gState.customKeyCallback != nil and gState.customKeyCallback(key, gState.buf):
      # Custom key was handled - refresh the prompt and continue
      refreshLine()
      continue

    # Then we check all other keys
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
      resetAttributes()
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
      clearCompletionDisplay()
      if gState.pos > 0:
        dec gState.pos
        deleteChar(gState.pos)
        refreshLine()
    
    # Delete
    of ord(KeyDelete):
      clearCompletionDisplay()
      if gState.pos < gState.buf.len:
        deleteChar(gState.pos)
        refreshLine()
    
    # Movement keys
    of ord(KeyLeft), ctrlKey('B'):
      clearCompletionDisplay()
      if gState.pos > 0:
        dec gState.pos
        refreshLine()
    
    of ord(KeyRight), ctrlKey('F'):
      clearCompletionDisplay()
      if gState.pos < gState.buf.len:
        inc gState.pos
        refreshLine()
    
    of ord(KeyHome), ctrlKey('A'):
      clearCompletionDisplay()
      gState.pos = 0
      refreshLine()
    
    of ord(KeyEnd), ctrlKey('E'):
      clearCompletionDisplay()
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
    
    # Intelligent Up/Down navigation (multiline-aware history navigation)
    of ord(KeyUp), ctrlKey('P'):
      let currentLine = getCurrentLineInBuffer()
      let totalLines = calculateTotalLines()
      
      # If we're on the first line of a multiline input, navigate history
      # If we're on a subsequent line, move up within the current input
      if currentLine == 0 or totalLines == 1:
        # Navigate to previous history entry
        if gState.historyPos > 0:
          dec gState.historyPos
          gState.buf = gState.history.entries[gState.historyPos]
          gState.pos = gState.buf.len
          refreshLine()
      else:
        # Move cursor up one line within current input
        let (currentLineNum, currentCol) = calculateWrappedPosition(gState.pos)
        if currentLineNum > 0:
          let newPos = findBufferPosForLineCol(currentLineNum - 1, currentCol)
          gState.pos = newPos
          refreshLine()
    
    of ord(KeyDown), ctrlKey('N'):
      let currentLine = getCurrentLineInBuffer()
      let totalLines = calculateTotalLines()
      let (currentLineNum, currentCol) = calculateWrappedPosition(gState.pos)
      
      # If we're on the last line or cursor is at the end, navigate history
      # Otherwise, move down within the current input
      if currentLine == totalLines - 1 or gState.pos == gState.buf.len:
        # Navigate to next history entry
        if gState.historyPos < gState.history.entries.len - 1:
          inc gState.historyPos
          gState.buf = gState.history.entries[gState.historyPos]
          gState.pos = gState.buf.len
          refreshLine()
        elif gState.historyPos == gState.history.entries.len - 1:
          inc gState.historyPos
          gState.buf = ""
          gState.pos = 0
          refreshLine()
      else:
        # Move cursor down one line within current input
        if currentLineNum < totalLines - 1:
          let newPos = findBufferPosForLineCol(currentLineNum + 1, currentCol)
          gState.pos = newPos
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
    
    # Key variants - Alternative movement keys (when keyVariants enabled)
    of altKey(ord(KeyLeft)):  # Ctrl-Left, Alt-Left variants -> word movement
      if gState.features.keyVariants and gState.features.wordMovement:
        gState.pos = moveToWordStart(gState.pos)
        refreshLine()
    
    of altKey(ord(KeyRight)):  # Ctrl-Right, Alt-Right variants -> word movement  
      if gState.features.keyVariants and gState.features.wordMovement:
        gState.pos = moveToWordEnd(gState.pos)
        refreshLine()
    
    of altKey(ord(KeyUp)):  # Ctrl-Up, Alt-Up variants -> multi-line up
      if gState.features.keyVariants and gState.features.multilineNav:
        # Move cursor up one line within the current input (always, regardless of history)
        let (currentLineNum, currentCol) = calculateWrappedPosition(gState.pos)
        if currentLineNum > 0:
          let newPos = findBufferPosForLineCol(currentLineNum - 1, currentCol)
          gState.pos = newPos
          refreshLine()
    
    of altKey(ord(KeyDown)):  # Ctrl-Down, Alt-Down variants -> multi-line down
      if gState.features.keyVariants and gState.features.multilineNav:
        # Move cursor down one line within the current input (always, regardless of history)
        let (currentLineNum, currentCol) = calculateWrappedPosition(gState.pos)
        let totalLines = calculateTotalLines()
        if currentLineNum < totalLines - 1:
          let newPos = findBufferPosForLineCol(currentLineNum + 1, currentCol)
          gState.pos = newPos
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
    
    # Interactive history search
    of ctrlKey('R'):  # Ctrl-R: Reverse history search
      if gState.features.historySearch:
        performHistorySearch(reverse = true)
        refreshLine()
    
    of ctrlKey('S'):  # Ctrl-S: Forward history search  
      if gState.features.historySearch:
        performHistorySearch(reverse = false)
        refreshLine()
    
    # Advanced history navigation
    of AltLess, ord(KeyPageUp):  # Alt-< or PgUp: Move to first history entry
      if gState.features.advancedControls or gState.features.historySearch:
        if gState.history.entries.len > 0:
          gState.historyPos = 0
          gState.buf = gState.history.entries[0]
          gState.pos = gState.buf.len
          refreshLine()
    
    of AltGreater, ord(KeyPageDown):  # Alt-> or PgDn: Move to last history entry
      if gState.features.advancedControls or gState.features.historySearch:
        gState.historyPos = gState.history.entries.len
        gState.buf = ""
        gState.pos = 0
        refreshLine()
    
    # Advanced completion and editing
    of AltEquals, AltQuestion:  # Alt-= or Alt-?: List all completions
      if gState.features.advancedControls:
        stdout.write("\n")
        let listText = if gState.completionListCallback != nil:
                         gState.completionListCallback(gState.buf)
                       else:
                         "Completion listing not configured"
        stdout.write(listText)
        stdout.write("\nPress any key to continue...")
        discard getKey()
        stdout.write("\n")
        refreshLine()
    
    of AltR:  # Alt-R: Revert line (undo all changes)
      if gState.features.advancedControls:
        gState.buf = ""
        gState.pos = 0
        refreshLine()
    
    of AltBackslash:  # Alt-\: Delete whitespace around cursor
      if gState.features.advancedEdit:
        # Find whitespace boundaries around cursor
        var start = gState.pos
        var endPos = gState.pos
        
        # Move backwards to find non-whitespace
        while start > 0 and gState.buf[start - 1] in " \t":
          dec start
        
        # Move forwards to find non-whitespace
        while endPos < gState.buf.len and gState.buf[endPos] in " \t":
          inc endPos
        
        if start < endPos:
          cutText(start, endPos)
          gState.pos = start
          refreshLine()
    
    of ord(KeyInsert):  # Insert: Paste from clipboard
      if gState.features.advancedCutPaste:
        gState.pos = pasteText(gState.pos)
        refreshLine()
    
    # Note: Ctrl-J (10) conflicts with KeyEnter2, Ctrl-M (13) conflicts with KeyEnter
    # Alternative Enter functionality is already handled by the main Enter case
    
    # Platform-specific controls
    of ctrlKey('Z'):  # Ctrl-Z: Suspend job (Linux/Unix only)
      when not defined(windows):
        if gState.features.advancedControls:
          stdout.write("\n")
          resetAttributes()
          # Send SIGTSTP to suspend the process
          when defined(posix):
            discard kill(getpid(), SIGTSTP)
          # Process will be suspended here until resumed with 'fg'
          refreshLine()
    
    # Function keys with individual enable/disable control
    of ord(KeyF1):
      if gState.features.functionKeys.f1Help:
        stdout.write("\n")
        let helpText = if gState.helpCallback != nil:
                         gState.helpCallback()
                       else:
                         defaultHelpCallback()
        stdout.write(helpText)
        discard getKey()  # Wait for user to press any key
        stdout.write("\n")
        refreshLine()
    
    of ord(KeyF2):
      if gState.features.functionKeys.f2History:
        stdout.write("\n")
        let historyText = if gState.historyDisplayCallback != nil:
                            gState.historyDisplayCallback(gState.history.entries)
                          else:
                            defaultHistoryDisplayCallback(gState.history.entries)
        stdout.write(historyText)
        discard getKey()  # Wait for user to press any key
        stdout.write("\n")
        refreshLine()
    
    of ord(KeyF3):
      if gState.features.functionKeys.f3ClearHistory:
        let shouldClear = if gState.clearHistoryCallback != nil:
                           gState.clearHistoryCallback()
                         else:
                           defaultClearHistoryCallback()
        if shouldClear:
          clearHistory()
          stdout.write("History cleared.\n")
        refreshLine()
    
    of ord(KeyF4):
      if gState.features.functionKeys.f4HistorySearch:
        # Search history with current input as pattern
        let matches = lookupHistory(gState.buf)
        if matches.len > 0:
          stdout.write("\n")
          stdout.write("History matches:\n")
          for i, match in matches:
            stdout.write(&"  {i + 1}: {match}\n")
          stdout.write("Press any key to continue...")
          discard getKey()
          stdout.write("\n")
        else:
          stdout.write("\nNo matches found.\n")
        refreshLine()
    
    # Debug mode (Ctrl-^)
    of CtrlCaret:
      if gState.features.functionKeys.debugMode:
        stdout.write("\n")
        let debugText = if gState.debugCallback != nil:
                          gState.debugCallback(CtrlCaret)
                        else:
                          defaultDebugCallback(CtrlCaret)
        stdout.write(debugText)
        discard getKey()  # Wait for user to press any key
        stdout.write("\n")
        refreshLine()
    
    # Regular character input
    else:
      if key >= 32 and key <= 126:  # Printable ASCII
        clearCompletionDisplay()  # Clear any previous completion display
        insertChar(char(key), gState.pos)
        inc gState.pos
        
        # Incremental update instead of full redraw
        if gState.pos == gState.buf.len:
          # Character added at end - just print it
          stdout.write(char(key))
          stdout.flushFile()
        else:
          # Character inserted in middle - need full refresh
          refreshLine()

## Public API functions
proc setDelimiter*(delim: string) =
  ## Set word delimiters for movement and editing
  gState.delimiter = delim

proc setExtendedFeatures*(features: ExtendedFeatures) =
  ## Configure which extended shortcut features are enabled
  gState.features = features

proc enableFeature*(feature: FeatureType, enable: bool = true) =
  ## Enable or disable a specific feature using type-safe enum
  case feature:
  of WordMovement: gState.features.wordMovement = enable
  of TextTransform: gState.features.textTransform = enable
  of AdvancedCutPaste: gState.features.advancedCutPaste = enable
  of MultilineNav: gState.features.multilineNav = enable
  of HistorySearch: gState.features.historySearch = enable
  of HelpSystem: gState.features.helpSystem = enable
  of AdvancedEdit: gState.features.advancedEdit = enable
  of KeyVariants: gState.features.keyVariants = enable
  of AdvancedControls: gState.features.advancedControls = enable

proc getExtendedFeatures*(): ExtendedFeatures =
  ## Get current extended feature configuration
  return gState.features

## Function key configuration functions
proc enableFunctionKey*(key: KeyCode, enable: bool = true) =
  ## Enable/disable individual function keys using KeyCode enum
  case key:
  of KeyF1: gState.features.functionKeys.f1Help = enable
  of KeyF2: gState.features.functionKeys.f2History = enable
  of KeyF3: gState.features.functionKeys.f3ClearHistory = enable
  of KeyF4: gState.features.functionKeys.f4HistorySearch = enable
  else: 
    echo "Warning: Only F1-F4 function keys are supported"

proc enableDebugMode*(enable: bool = true) =
  ## Enable/disable debug mode (Ctrl-^) separately since it's not a KeyCode
  gState.features.functionKeys.debugMode = enable

proc setFunctionKeyFeatures*(features: FunctionKeyFeatures) =
  ## Set all function key features at once
  gState.features.functionKeys = features

proc getFunctionKeyFeatures*(): FunctionKeyFeatures =
  ## Get current function key configuration
  return gState.features.functionKeys

proc registerCompletionCallback*(callback: CompletionCallback) =
  ## Register completion callback
  gState.completionCallback = callback

proc registerHistorySaveCallback*(callback: HistorySaveCallback) =
  ## Register custom history save callback
  gState.historySaveCallback = callback

proc registerHistoryLookupCallback*(callback: HistoryLookupCallback) =
  ## Register custom history lookup callback
  gState.historyLookupCallback = callback

## Function key and UI callback registration
proc registerHelpCallback*(callback: HelpCallback) =
  ## Register custom help display callback for F1
  gState.helpCallback = callback

proc registerHistoryDisplayCallback*(callback: HistoryDisplayCallback) =
  ## Register custom history display callback for F2
  gState.historyDisplayCallback = callback

proc registerClearHistoryCallback*(callback: ClearHistoryCallback) =
  ## Register custom history clear confirmation callback for F3
  gState.clearHistoryCallback = callback

proc registerDebugCallback*(callback: DebugCallback) =
  ## Register custom debug mode callback for Ctrl-^
  gState.debugCallback = callback

proc registerHistorySearchCallback*(callback: HistorySearchCallback) =
  ## Register custom history search callback for Ctrl-R/S
  gState.historySearchCallback = callback

proc registerCompletionListCallback*(callback: CompletionListCallback) =
  ## Register custom completion list display callback for Alt-=/? 
  gState.completionListCallback = callback

proc registerCustomKeyCallback*(callback: CustomKeyCallback) =
  ## Register custom key combination callback (e.g., for Ctrl+Tab mode switching)
  gState.customKeyCallback = callback

proc setHistoryEntries*(entries: seq[string]) =
  ## Set history entries directly (useful with custom loaders)
  gState.history.entries = entries

proc getHistoryEntries*(): seq[string] =
  ## Get current history entries (useful with custom savers)
  return gState.history.entries

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

## Initialize the linecross state
proc initLinecross*(features: ExtendedFeatures = BasicFeatures) =
  ## Initialize linecross with optional extended features
  gState = LinecrossState()
  gState.isWindows = defined(windows)
  gState.delimiter = DefaultDelimiter
  gState.history = History(maxLines: DefaultHistoryMaxLines)
  gState.promptColor = fgDefault
  gState.promptStyle = {}
  gState.pagingEnabled = false
  gState.features = features
  gState.clipBoard = ""
  
  # Initialize bash completion state
  gState.bashCompletionWaiting = false
  gState.bashCompletionPrefix = ""
    
  # Get initial screen size
  let (rows, cols) = getScreenSize()
  gState.rows = rows
  gState.cols = cols
  
  # Initialize persistent mode settings
  gState.outputMode = omNormal
  gState.inputAreaHeight = 1
  gState.inputAreaStartRow = rows
  gState.scrollableAreaHeight = rows - 1  
  gState.persistentConfig = DefaultPersistentConfig
  gState.savedInputState = InputState()

  # Register so we reset on forced exit
  exitprocs.addExitProc(resetAttributes)

## Persistent input area management functions

proc calculateInputAreaHeight*(): int =
  ## Calculate how many lines the current input buffer needs
  if gState.buf.len == 0:
    return 1  # Always need at least one line for the prompt
  
  let promptLen = calculatePromptDisplayLength()  
  let totalChars = promptLen + gState.buf.len
  return max(1, (totalChars + gState.cols - 1) div gState.cols)

proc saveInputState*() =
  ## Save the current input state for later restoration
  gState.savedInputState = InputState(
    buffer: gState.buf,
    cursorPos: gState.pos,
    promptText: gState.prompt,
    displayLines: calculateInputAreaHeight()
  )

proc restoreInputState*() =
  ## Restore the previously saved input state
  gState.buf = gState.savedInputState.buffer
  gState.pos = gState.savedInputState.cursorPos
  gState.prompt = gState.savedInputState.promptText
  
proc moveToInputAreaStart*() =
  ## Move cursor to the start of the input area
  if gState.outputMode == omPersistent:
    # In persistent mode, move to the input area start row
    stdout.write(fmt"\x1b[{gState.inputAreaStartRow};1H")
  else:
    # In normal mode, just go to beginning of current line
    stdout.write("\r")

proc clearInputArea*() =
  ## Clear the input area completely
  moveToInputAreaStart()
  stdout.write("\x1b[0J")  # Clear from cursor to end of screen

proc restoreInputArea*() =
  ## Restore the input area with saved state
  moveToInputAreaStart()
  
  # Display prompt with color
  setTextColor(gState.promptColor, gState.promptStyle)
  stdout.write(gState.savedInputState.promptText)
  resetAttributes()
  
  # Display the saved buffer
  stdout.write(gState.savedInputState.buffer)
  
  # Position cursor at saved position
  let promptLen = calculatePromptDisplayLength()
  let totalCharsBeforeCursor = promptLen + gState.savedInputState.cursorPos
  let cursorLine = totalCharsBeforeCursor div gState.cols
  let cursorCol = totalCharsBeforeCursor mod gState.cols
  
  # Move to correct position
  moveToInputAreaStart()
  if cursorLine > 0:
    stdout.write(fmt"\x1b[{cursorLine}B")  # Move down to target line
  stdout.write(fmt"\x1b[{cursorCol + 1}G")  # Move to target column (1-based)
  
  stdout.flushFile()

proc enterPersistentMode*() =
  ## Switch to persistent input area mode
  if gState.outputMode == omPersistent:
    return  # Already in persistent mode
  
  gState.outputMode = omPersistent
  
  # Calculate optimal input area height
  let neededHeight = min(calculateInputAreaHeight(), gState.persistentConfig.inputAreaMaxHeight)
  gState.inputAreaHeight = max(1, neededHeight)
  
  # Calculate area boundaries
  gState.inputAreaStartRow = gState.rows - gState.inputAreaHeight + 1  
  gState.scrollableAreaHeight = gState.rows - gState.inputAreaHeight
  
  # Save current state and clear screen to establish areas
  saveInputState()
  clearInputArea()
  restoreInputArea()

proc exitPersistentMode*() =
  ## Return to normal single-line input mode
  if gState.outputMode == omNormal:
    return  # Already in normal mode
    
  gState.outputMode = omNormal
  gState.inputAreaHeight = 1
  gState.inputAreaStartRow = gState.rows
  gState.scrollableAreaHeight = gState.rows - 1
  
  # Clear screen and restore normal operation
  stdout.write("\x1b[2J\x1b[H")  # Clear screen and move to top
  refreshLine()

proc isInPersistentMode*(): bool =
  ## Check if currently in persistent input area mode
  return gState.outputMode == omPersistent

proc setPersistentModeConfig*(config: PersistentModeConfig) =
  ## Set configuration for persistent mode
  gState.persistentConfig = config
  
  # If already in persistent mode, recalculate areas
  if gState.outputMode == omPersistent:
    let neededHeight = min(calculateInputAreaHeight(), config.inputAreaMaxHeight)
    gState.inputAreaHeight = max(1, neededHeight)
    gState.inputAreaStartRow = gState.rows - gState.inputAreaHeight + 1
    gState.scrollableAreaHeight = gState.rows - gState.inputAreaHeight

proc getPersistentModeConfig*(): PersistentModeConfig =
  ## Get current persistent mode configuration
  return gState.persistentConfig

## Enhanced completion callback registration
proc registerCompletionDisplayCallback*(callback: CompletionDisplayCallback) =
  ## Register callback for displaying completions
  gState.completionDisplayCallback = callback

proc registerCompletionClearCallback*(callback: CompletionClearCallback) =
  ## Register callback for clearing completion display
  gState.completionClearCallback = callback

## Phase 2: Output display functions for persistent mode

proc getTerminalSize(): (int, int) =
  ## Get current terminal size, with fallback
  try:
    let size = terminalSize()
    return (size.w, size.h)
  except:
    return (80, 24)  # Fallback size

proc displayContentAbove(lines: seq[string]) =
  ## Display content lines in the scrollable area above input
  # Move to top of scrollable area
  stdout.write(&"\x1b[{gState.inputAreaStartRow - gState.scrollableAreaHeight}H")
  
  # Clear the scrollable area
  for i in 0..<gState.scrollableAreaHeight:
    stdout.write(&"\x1b[{gState.inputAreaStartRow - gState.scrollableAreaHeight + i}H")
    stdout.write("\x1b[K")  # Clear line
  
  # Display content lines
  for i, line in lines:
    if i < gState.scrollableAreaHeight:
      stdout.write(&"\x1b[{gState.inputAreaStartRow - gState.scrollableAreaHeight + i}H")
      # Truncate line if it's too wide for terminal
      let (termWidth, _) = getTerminalSize()
      let displayLine = if line.len > termWidth: line[0..<termWidth-1] else: line
      stdout.write(displayLine)
  
  stdout.flushFile()

proc displayContentWithPaging(lines: seq[string], availableHeight: int) =
  ## Display content with basic paging when it exceeds available space
  let pageSize = availableHeight - 1  # Reserve one line for paging indicator
  let totalPages = (lines.len + pageSize - 1) div pageSize  # Ceiling division
  
  # For now, show the last page (most recent content)
  # This could be enhanced to support interactive paging later
  let lastPageStart = max(0, lines.len - pageSize)
  let lastPageLines = lines[lastPageStart..<lines.len]
  
  # Move to top of scrollable area
  stdout.write(&"\x1b[{gState.inputAreaStartRow - gState.scrollableAreaHeight}H")
  
  # Clear the scrollable area
  for i in 0..<gState.scrollableAreaHeight:
    stdout.write(&"\x1b[{gState.inputAreaStartRow - gState.scrollableAreaHeight + i}H")
    stdout.write("\x1b[K")  # Clear line
  
  # Display the page content
  for i, line in lastPageLines:
    stdout.write(&"\x1b[{gState.inputAreaStartRow - gState.scrollableAreaHeight + i}H")
    let (termWidth, _) = getTerminalSize()
    let displayLine = if line.len > termWidth: line[0..<termWidth-1] else: line
    stdout.write(displayLine)
  
  # Show paging indicator if content was truncated
  if lines.len > pageSize:
    let indicatorRow = gState.inputAreaStartRow - 1
    stdout.write(&"\x1b[{indicatorRow}H")
    stdout.write(&"... ({lines.len - pageSize} more lines above) ...")
  
  stdout.flushFile()

proc printAboveInput*(content: string) =
  ## Print content above the persistent input area
  ## This is the main function for displaying output while preserving input
  if gState.outputMode != omPersistent:
    # If not in persistent mode, just print normally
    echo content
    return
  
  # Save current input state
  saveInputState()
  
  # Get terminal dimensions
  let (termWidth, termHeight) = getTerminalSize()
  let availableHeight = gState.scrollableAreaHeight
  
  # Split content into lines and handle overflow
  let contentLines = content.split('\n')
  let totalContentLines = contentLines.len
  
  if totalContentLines <= availableHeight:
    # Content fits within available space
    displayContentAbove(contentLines)
  else:
    # Content exceeds available space - implement basic paging
    displayContentWithPaging(contentLines, availableHeight)
  
  # Restore input area
  restoreInputArea()

## Phase 3: Temporary display below input area

proc printBelow*(content: string, clearAfterMs: int = 0) =
  ## Print content temporarily below the persistent input area
  ## If clearAfterMs > 0, automatically clear after the specified time
  if gState.outputMode != omPersistent:
    # If not in persistent mode, just print normally
    echo content
    return
  
  # Save current cursor position
  let currentRow = gState.inputAreaStartRow + getCurrentLineInBuffer()
  let (_, currentCol) = calculateWrappedPosition(gState.pos)
  
  # Calculate how many lines below the input area we need
  let contentLines = content.split('\n')
  let neededLines = contentLines.len
  
  # Move to position below input area
  let displayStartRow = gState.inputAreaStartRow + gState.inputAreaHeight
  
  # Display content below input area
  for i, line in contentLines:
    let targetRow = displayStartRow + i
    stdout.write(&"\x1b[{targetRow}H")
    stdout.write("\x1b[K")  # Clear line first
    
    # Truncate line if it's too wide
    let (termWidth, _) = getTerminalSize()
    let displayLine = if line.len > termWidth: line[0..<termWidth-1] else: line
    stdout.write(displayLine)
  
  # Restore cursor to input area
  stdout.write(&"\x1b[{currentRow}H")
  if currentCol > 0:
    stdout.write(&"\x1b[{currentCol}C")
  
  stdout.flushFile()
  
  # If auto-clear is requested, set up clearing (for future enhancement)
  # This would require async support or threading for automatic clearing
  if clearAfterMs > 0:
    # For now, just store the clear request - would be enhanced later
    gState.belowContentClearMs = clearAfterMs

proc clearBelow*() =
  ## Clear content displayed below the input area
  if gState.outputMode != omPersistent:
    return
  
  # Save current cursor position  
  let currentRow = gState.inputAreaStartRow + getCurrentLineInBuffer()
  let (_, currentCol) = calculateWrappedPosition(gState.pos)
  
  # Clear lines below input area (clear a reasonable number of lines)
  let displayStartRow = gState.inputAreaStartRow + gState.inputAreaHeight
  let (_, termHeight) = getTerminalSize()
  let linesToClear = min(10, termHeight - displayStartRow)  # Clear up to 10 lines or until bottom
  
  for i in 0..<linesToClear:
    let targetRow = displayStartRow + i
    stdout.write(&"\x1b[{targetRow}H")
    stdout.write("\x1b[K")  # Clear line
  
  # Restore cursor to input area
  stdout.write(&"\x1b[{currentRow}H") 
  if currentCol > 0:
    stdout.write(&"\x1b[{currentCol}C")
  
  stdout.flushFile()
