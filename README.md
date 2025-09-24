# Linecross - Simple Cross-platform Readline Replacement

**Linecross.nim** is a multiline readline replacement library for Nim. In addition to regular editing capability it also has history support including search, callback support for bash style tab completion and callback for custom key handling.

## Key Features

- **Cross-platform support** - Works on Windows, Linux, Unix, macOS
- **History management** - Persistent command history with navigation and incremental search
- **Tab completion** - Customizable completion system with double-tab support
- **Cut/paste operations** - Internal and system clipboard integration
- **Color support** - Customizable prompt coloring
- **Multiline editing** - Intelligent cursor positioning and context-aware navigation
- **Callback system** - Extensible with custom key handlers and completion functions
- **Minimal dependencies** - Uses only Nim's standard library (std/terminal)

## Quick Start

```nim
import linecross

# Initialize the library
initLinecross()

# Simple usage
while true:
  let input = readline("nim> ")
  if input == "quit":
    break
  echo "You typed: ", input

# Save history on exit
discard saveHistory("history.txt")
```

## Advanced Usage

### History Management

```nim
# Load existing history
discard loadHistory("myapp_history.txt")

# Configure history
initLinecross(enableHistory = true)

# Custom history callbacks
proc loadMyHistory(): seq[string] =
  # Your custom history loading logic
  result = @["previous", "commands"]

proc saveMyHistory(entries: seq[string]): bool =
  # Your custom history saving logic
  return true

registerHistoryLoadCallback(loadMyHistory)
registerHistorySaveCallback(saveMyHistory)
```

### Tab Completion

```nim
# Custom completion callback
proc myCompletions(buffer: string, cursorPos: int, isSecondTab: bool): string =
  let commands = ["help", "quit", "save", "load"]
  let word = buffer.split(' ')[^1]
  
  for cmd in commands:
    if cmd.startsWith(word):
      return cmd[word.len..^1]  # Return remaining part
  
  if isSecondTab:
    # Show available options on second tab
    echo ""
    echo "Available: ", commands.join(", ")
    return ""
  
  return ""

registerCompletionCallback(myCompletions)
```

### Color Customization

```nim
import std/terminal

# Set prompt color
setPromptColor(fgBlue, {styleBright})

# Or use in readline directly
let input = readline("$ ".fgRed & "nim> ".fgGreen)
```

### Custom Key Handlers

```nim
proc customKeyHandler(keyCode: int, buffer: string): bool =
  case keyCode:
  of 6:  # Ctrl+F
    echo "\nSpecial function triggered!"
    return true  # Key was handled
  else:
    return false  # Let default handler process

registerCustomKeyCallback(customKeyHandler)
```

## Keyboard Shortcuts

### Basic Movement
- `Left Arrow`, `Ctrl-B` - Move back one character
- `Right Arrow`, `Ctrl-F` - Move forward one character  
- `Home`, `Ctrl-A` - Move to start of line
- `End`, `Ctrl-E` - Move to end of line

### Word Movement
- `Alt-B` - Move back one word
- `Alt-F` - Move forward one word
- `Ctrl-Left` - Move back one word (alternative)
- `Ctrl-Right` - Move forward one word (alternative)

### Editing
- `Backspace` - Delete character before cursor
- `Delete`, `Ctrl-D` - Delete character under cursor (Ctrl-D: EOF if empty)
- `Ctrl-K` - Cut from cursor to end of line
- `Ctrl-U` - Cut from start of line to cursor

### History Navigation
- `Up Arrow`, `Ctrl-P` - Previous command in history
- `Down Arrow`, `Ctrl-N` - Next command in history
- `Ctrl-R` - Incremental reverse history search (if enabled)
- `Ctrl-S` - Incremental forward history search (if enabled)

*Note: In multiline mode, Up/Down intelligently switch between line navigation and history based on cursor position.*

### Cut/Paste
- `Ctrl-Y` - Paste from clipboard
- `Ctrl-V` - Paste from clipboard (alternative)
- `Insert` - Paste from clipboard

### Control
- `Tab` - Trigger completion (second tab shows options)
- `Ctrl-L` - Clear screen and redisplay line
- `Ctrl-C` - Abort current line (exit)
- `Enter` - Accept current line

## Multiline Editing

Linecross supports multiline input with intelligent navigation.

**Smart Up/Down behavior:**
- **First line + Up** → Navigate to previous history
- **Middle lines + Up/Down** → Move between lines in current input  
- **Last line + Down** → Navigate to next history
- **Any line + Ctrl-P/Ctrl-N** → Always navigate history

## Incremental History Search

When enabled with `enableHistorySearch = true`, linecross enables incremental search through command history:

```nim
# Enable during initialization
initLinecross(enableHistory = true, enableHistorySearch = true)

# Use Ctrl-R to start reverse search
# Type characters to search - matches appear in real-time
# Press Enter to accept, Escape to cancel
```

**Search Interface:**
```
(reverse-i-search)`pattern': matching_command_here
```

**Search Controls:**
- `Ctrl-R` - Start/continue reverse search
- `Ctrl-S` - Start/continue forward search
- `Type characters` - Add to search pattern (real-time matching)
- `Backspace` - Remove character from pattern
- `Enter` - Accept current match and execute
- `Escape` / `Ctrl-G` - Cancel search and restore original input

## Configuration Options

### Initialization
```nim
# Basic initialization
initLinecross()

# With history disabled
initLinecross(enableHistory = false)

# With incremental history search enabled
initLinecross(enableHistory = true, enableHistorySearch = true)
```

### Word Delimiters
```nim
# Customize what constitutes word boundaries
setDelimiter(" !\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~")
```

### System Clipboard
Compile with `-d:useSystemClipboard` to enable system clipboard integration:
```bash
nim c -d:useSystemClipboard myapp.nim
```

## Callback Reference

### Core Callbacks
- `CustomKeyCallback` - Handle custom key combinations
- `CompletionCallback` - Provide tab completion
- `HistoryLoadCallback` - Custom history loading
- `HistorySaveCallback` - Custom history saving

### Callback Registration
```nim
registerCustomKeyCallback(proc(key: int, buf: string): bool = ...)
registerCompletionCallback(proc(buf: string, pos: int, secondTab: bool): string = ...)
registerHistoryLoadCallback(proc(): seq[string] = ...)
registerHistorySaveCallback(proc(entries: seq[string]): bool = ...)
```

## API Reference

### Core Functions
- `readline(prompt: string): string` - Main input function
- `initLinecross(enableHistory: bool = true)` - Initialize library

### History Functions  
- `addToHistory(line: string)` - Add line to history
- `loadHistory(filename: string): bool` - Load history from file
- `saveHistory(filename: string): bool` - Save history to file
- `clearHistory()` - Clear all history

### Clipboard Functions
- `cutText(startPos, endPos: int)` - Cut text range to clipboard
- `pasteText(pos: int): int` - Paste at position, return new position
- `copyToClipboard(text: string)` - Copy to clipboard

### Word Movement Functions
- `moveToWordStart(pos: int): int` - Find start of word
- `moveToWordEnd(pos: int): int` - Find end of word

### Utility Functions
- `setPromptColor(color: ForegroundColor, style: set[Style])` - Set prompt appearance
- `setDelimiter(delim: string)` - Configure word boundaries

## Examples

### Simple REPL
```nim
import linecross

proc main() =
  initLinecross()
  discard loadHistory(".myrepl_history")
  
  echo "Simple REPL - type 'quit' to exit"
  
  while true:
    let input = readline("repl> ")
    
    if input == "quit" or input == "":
      break
    
    # Process input
    echo "Result: ", input.toUpperAscii()
  
  discard saveHistory(".myrepl_history")

main()
```

### Advanced Shell
```nim
import linecross, std/[strutils, terminal]

proc completionHandler(buffer: string, cursorPos: int, isSecondTab: bool): string =
  let commands = ["help", "list", "create", "delete", "quit"]
  let words = buffer.split(' ')
  let currentWord = if words.len > 0: words[^1] else: ""
  
  var matches: seq[string] = @[]
  for cmd in commands:
    if cmd.startsWith(currentWord):
      matches.add(cmd)
  
  if matches.len == 1:
    return matches[0][currentWord.len..^1] & " "
  elif matches.len > 1 and isSecondTab:
    echo ""
    echo "Available: ", matches.join(", ")
    return ""
  
  return ""

proc main() =
  initLinecross(enableHistory = true)
  registerCompletionCallback(completionHandler)
  setPromptColor(fgCyan, {styleBright})
  
  discard loadHistory(".shell_history")
  
  while true:
    let input = readline("shell$ ")
    
    case input:
    of "quit", "exit": break
    of "help":
      echo "Commands: help, list, create, delete, quit"
    of "clear":
      clearScreen()
    else:
      echo "Unknown command: ", input
  
  discard saveHistory(".shell_history")

main()
```

## License

MIT License
