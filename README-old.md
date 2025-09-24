# Linecross

A configurable Nim port of the [Crossline library](https://github.com/jcwangxp/Crossline). Linecross is a small, self-contained, cross-platform readline replacement with modular extended shortcuts.

Alternatives to this library are readline, nimnoise etc.

**NOTE: This package is coded via AI and I admit it may be buggy still!**

## Features

- **Cross-platform support**: Windows, Linux/Unix, macOS
- **Configurable shortcuts**: 15-65+ shortcuts via feature flags (Basic/Essential/Standard/Full)
- **History management**: Pluggable save/load history with search capabilities
- **Autocomplete support**: Customizable completion callbacks
- **Color text support**: Colors for prompts and completions
- **Cursor and screen control**: Paging and cursor positioning APIs
- **Optional system clipboard**: Via libclip (compile-time flag)

## Quick Start

### Basic Usage

```nim
import linecross

# Simple readline
initLinecross()
let line = readline("Prompt> ")
echo "You entered: ", line
```

### With Extended Features

```nim
import linecross

# Configure extended shortcuts (choose your feature level)
initLinecross(StandardFeatures)  # 40 shortcuts including word movement, text transform

proc myCompletionHook(buf: string, completions: var Completions) =
  let commands = @["help", "exit", "list", "create", "delete", "uppercase_demo"]
  for cmd in commands:
    if cmd.startsWith(buf.split(' ')[^1]):
      addCompletion(completions, cmd, "Demo: " & cmd)

# Set up completion
registerCompletionCallback(myCompletionHook)

# Load history
discard loadHistory("myapp_history.txt")

echo "Try extended shortcuts:"
echo "- Alt-B/F: Word navigation"  
echo "- Alt-U/L/C: Text transformation"
echo "- Ctrl-X/Y: Cut/paste operations"

# Main loop
while true:
  let line = readline("MyApp> ")
  if line == "exit":
    break
  echo "Command: ", line

# Save history
discard saveHistory("myapp_history.txt")
```

## API Reference

### Core Functions

- `readline(prompt: string, initialText: string = ""): string` - Main readline function
- `initLinecross(features: ExtendedFeatures = BasicFeatures)` - Initialize with feature configuration

### History Management

- `loadHistory(filename: string): bool` - Load history from file
- `saveHistory(filename: string): bool` - Save history to file
- `clearHistory()` - Clear all history entries
- `addToHistory(line: string)` - Manually add line to history

### Completion System

- `registerCompletionCallback(callback: CompletionCallback)` - Register completion function
- `addCompletion(completions: var Completions, word, help: string, ...)` - Add completion item
- `setHints(completions: var Completions, hints: string, ...)` - Set completion hints

### Configuration

- `setDelimiter(delim: string)` - Set word delimiters for movement/editing
- `setPromptColor(color: ForegroundColor, style: set[Style])` - Set prompt color and style
- `enablePaging(enable: bool)` - Enable/disable paging

### Extended Features Configuration

- `setExtendedFeatures(features: ExtendedFeatures)` - Configure feature flags
- `enableFeature(feature: string, enable: bool)` - Enable/disable specific features
- `getExtendedFeatures(): ExtendedFeatures` - Get current feature configuration

**Feature Sets:**
```nim
BasicFeatures      # 15 shortcuts - essential functionality only
EssentialFeatures  # 25 shortcuts - adds word movement + cut/paste  
StandardFeatures   # 40 shortcuts - adds text transformation + multiline
FullFeatures       # 65+ shortcuts - all extended features enabled
```

### Color Support

```nim
# Uses std/terminal colors and styles
import std/terminal

# Available colors: fgRed, fgGreen, fgBlue, fgYellow, fgMagenta, fgCyan, fgWhite, fgDefault
# Available styles: styleBright, styleDim, styleItalic, styleUnderscore, etc.

setPromptColor(fgCyan, {styleBright})
addCompletion(completions, "command", "help text", fgGreen, fgYellow)
```

### Screen and Cursor Control

- `getScreenSize(): (int, int)` - Get terminal size (rows, cols)
- `getCursorPos(): (int, int)` - Get cursor position
- `setCursorPos(row, col: int)` - Set cursor position
- `clearScreen()` - Clear the screen
- `hideCursor(hide: bool)` - Hide/show cursor

## Keyboard Shortcuts

### Universal Shortcuts (All Feature Levels)

**Basic Movement:**
- `Ctrl-B`, `Left` - Move back a character
- `Ctrl-F`, `Right` - Move forward a character
- `Ctrl-A`, `Home` - Move to start of line
- `Ctrl-E`, `End` - Move to end of line

**History Navigation:**
- `Up`, `Ctrl-P` - Previous history
- `Down`, `Ctrl-N` - Next history

**Basic Editing:**
- `Backspace` - Delete character before cursor
- `Delete`, `Ctrl-D` - Delete character under cursor (Ctrl-D: EOF if empty)
- `Ctrl-K` - Kill to end of line
- `Ctrl-U` - Kill to beginning of line

**Control:**
- `Enter` - Accept line
- `Ctrl-C`, `Ctrl-G` - Abort/exit
- `Ctrl-L` - Clear screen
- `Tab` - Trigger completion

### Extended Shortcuts (Feature-Dependent)

**Word Movement** (`wordMovement` feature):
- `Alt-B` - Move back one word
- `Alt-F` - Move forward one word

**Text Transformation** (`textTransform` feature):
- `Alt-U` - Uppercase current/following word
- `Alt-L` - Lowercase current/following word
- `Alt-C` - Capitalize current/following word

**Advanced Cut/Paste** (`advancedCutPaste` feature):
- `Ctrl-X` - Cut entire line to clipboard
- `Ctrl-Y`, `Ctrl-V` - Paste from clipboard
- `Ctrl-W` - Cut from cursor to last space
- `Alt-D` - Cut word forward
- `Alt-Backspace` - Cut word backward

**Advanced Editing** (`advancedEdit` feature):
- `Ctrl-T` - Transpose (swap) current and previous characters

### Feature Level Summary

| Feature Set | Shortcuts | Includes |
|-------------|-----------|----------|
| **BasicFeatures** | 15 | Essential movement, editing, history, completion |
| **EssentialFeatures** | 25 | + Word movement, cut/paste operations |
| **StandardFeatures** | 40 | + Text transformation, multiline support |
| **FullFeatures** | 65+ | + All advanced features |

## Platform Support

### All Platforms (Windows, Linux, macOS, Unix)
- Uses Nim's `terminal` module for cross-platform compatibility
- Full keyboard shortcut support across all platforms
- Color support using Nim's built-in color management
- Cursor positioning and screen control via terminal module
- Fallback ANSI escape codes when needed

## Building and Installation

### Prerequisites
- Nim 2.2.4+ (may work with older)
- Optional: `libclip` for system clipboard support

### Installation

```bash
# Install via nimble (if published)
nimble install linecross

# Or clone and build locally
git clone <repository>
cd linecross
nimble install
```

### Compilation

```bash
# Basic compilation (internal clipboard only)
nim c -r example.nim                    # Basic example
nim c -r example_extended.nim           # Extended features demo

# With system clipboard support
nim c -d:useSystemClipboard -r example_extended.nim

```

## Clipboard Integration

### Internal Clipboard (Always Available)
All cut/paste operations use an internal clipboard that works across all platforms and terminal types.

### System Clipboard (Optional)
For integration with system clipboard (copy from/paste to other applications):

```bash
# Compile with system clipboard support  
nim c -d:useSystemClipboard -r your_app.nim
```

**Features with system clipboard:**
- `Ctrl-X/Y/V` operations sync with system clipboard
- Graceful fallback to internal clipboard if system access fails
- Works across Windows, Linux, and macOS


## License

MIT License - Same as the original Linecross library