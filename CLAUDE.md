# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Linecross is a cross-platform readline replacement library.

## Build Commands

### Check for compilation errors
```bash
nim check linecross.nim                 # Check library
```

### Build Examples
```bash
nim c -r example.nim                    # Compile and run basic example
nim c -r example2.nim                   # Enhanced example with colors
nim c -r example_sql.nim                # SQL parser example
nim c -r example_extended.nim           # Extended shortcuts demo
nim c -r example_history_callbacks.nim  # Custom history callbacks demo
```

## Architecture

### Core Components

**Nim Library (`linecross.nim`)**:
- Uses `std/terminal` module for cross-platform compatibility
- Strong typing and exception handling
- Simplified cursor positioning and color management
- Modular extended shortcuts system (15-65+ shortcuts based on configuration)

### Key Features
- Comprehensive keyboard shortcuts 15-65+ configurable
- Modular feature system with predefined configuration sets
- Multi-line editing support with intelligent cursor movement
- Autocomplete system with customizable callbacks
- Color support for prompts, completions, and syntax highlighting
- Paging control for long output
- Cross-platform cursor and screen control APIs

### Examples
- `example.nim`: Basic readline with completion and history
- `example2.nim`: Advanced features including colors and paging
- `example_sql.nim`: Complete SQL shell demonstrating parser integration
- `example_extended.nim`: Demonstrates configurable extended shortcuts
- `example_history_callbacks.nim`: Shows how to implement custom history callbacks

## Keyboard Shortcuts

The implementations now offer different configuration options:
- **Nim Implementation**: Configurable 15-65+ shortcuts via feature flags

### Universal Shortcuts

**Basic Movement**:
- `Ctrl-B`, `Left` - Move back a character
- `Ctrl-F`, `Right` - Move forward a character  
- `Ctrl-A`, `Home` - Move cursor to start of line
- `Ctrl-E`, `End` - Move cursor to end of line

**Basic Editing**:
- `Backspace` - Delete character before cursor
- `Delete`, `Ctrl-D` - Delete character under cursor (Ctrl-D: EOF if empty)

**History Navigation**:
- `Ctrl-P`, `Up` - Fetch previous line in history
- `Ctrl-N`, `Down` - Fetch next line in history

**Line Operations**:
- `Ctrl-K` - Cut from cursor to end of line
- `Ctrl-U` - Cut from start of line to cursor
- `Ctrl-L` - Clear screen and redisplay line
- `Ctrl-W` - **DIFFERENT**: Nim=move to word start, C=cut to whitespace

**Completion and Control**:
- `Tab` - Autocomplete
- `Enter` - Accept line
- `Ctrl-C`, `Ctrl-G` - Abort line

### Extended Shortcuts (C Implementation Only)

**Misc Commands**:
- `F1` - Show comprehensive help
- `Ctrl-^` - Enter keyboard debugging mode

**Advanced Movement**:
- `Alt-B`, `ESC+Left`, `Ctrl-Left`, `Alt-Left` - Move back a word
- `Alt-F`, `ESC+Right`, `Ctrl-Right`, `Alt-Right` - Move forward a word
- `Up`, `ESC+Up`, `Ctrl-Up`, `Alt-Up` - Move cursor to up line (multi-line)
- `Down`, `ESC+Down`, `Ctrl-Down`, `Alt-Down` - Move cursor to down line (multi-line)

**Advanced Editing**:
- `Alt-U` - Uppercase current or following word
- `Alt-L` - Lowercase current or following word  
- `Alt-C` - Capitalize current or following word
- `Alt-\` - Delete whitespace around cursor
- `Ctrl-T` - Transpose previous character with current character

**Cut & Paste**:
- `Ctrl-X` - Cut whole line
- `Alt-Backspace`, `ESC+Backspace`, `Ctrl-Backspace` - Cut word to left of cursor
- `Alt-D`, `ESC+Del`, `Alt-Del`, `Ctrl-Del` - Cut word following cursor  
- `Ctrl-W` - Cut to left till whitespace (not word)
- `Ctrl-Y`, `Ctrl-V`, `Insert` - Paste last cut text

**Advanced Completion**:
- `Alt-=`, `Alt-?` - List possible completions

**Advanced History**:
- `Alt-<`, `PgUp` - Move to first line in history
- `Alt->`, `PgDn` - Move to end of input history
- `Ctrl-R`, `Ctrl-S` - Interactive history search
- `F4` - Search history with current input
- `F2` - Show history
- `F3` - Clear history (with confirmation)

**Control Commands**:
- `Ctrl-J`, `Ctrl-M` - Alternative Enter keys
- `Alt-R` - Revert line (undo all changes)
- `Ctrl-Z` - Suspend job (Linux only, use `fg` to resume)

### Platform-Specific Notes

**Windows**: Full support for `Ctrl-key` and `Alt-key` combinations
**Linux/Unix**: Some `Alt-key` shortcuts may need `ESC+key` instead
**Terminal Limitations**: 
- vt100: Limited function key support
- Some terminals only support left Alt key
- SecureCRT and other emulators have specific key mapping requirements

### Multi-line Editing Behavior

In multi-line mode, `Up`/`Down` key behavior is context-sensitive:
- **First line**: `Down` moves to next line, `Up` fetches history
- **Middle lines**: `Up`/`Down` move between lines
- **Last line (cursor not at end)**: `Up` moves up, `Down` fetches history  
- **Last line (cursor at end)**: `Up`/`Down` work as history shortcuts

Use `Ctrl-P`/`Ctrl-N` for consistent history navigation regardless of position.

### Getting Help

- Press `F1` in C implementation for complete interactive help
- Use `Ctrl-^` for keyboard debugging to see key codes
- In history search mode, `F1` shows search pattern syntax

## Nim Extended Features Configuration

The Nim implementation introduces a modular approach to extended shortcuts:

### Feature Flag System

```nim
type
  ExtendedFeatures* = object
    wordMovement*: bool      # Alt-B/F, Ctrl-Left/Right word navigation
    textTransform*: bool     # Alt-U/L/C for case changes
    advancedCutPaste*: bool  # Alt-D, Alt-Backspace, Ctrl-X, Ctrl-Y/V
    multilineNav*: bool      # Ctrl-Up/Down for multi-line navigation  
    historySearch*: bool     # Ctrl-R, F4 interactive history search
    helpSystem*: bool        # F1 help, Ctrl-^ debug mode
    advancedEdit*: bool      # Ctrl-T transpose, Alt-\ whitespace cleanup
```

### Predefined Configuration Sets

1. **BasicFeatures** (15 shortcuts)
   - Current basic implementation
   - Essential movement, editing, history, completion
   - Suitable for simple applications

2. **EssentialFeatures** (25 shortcuts)  
   - BasicFeatures + wordMovement + advancedCutPaste
   - Adds word navigation and clipboard operations
   - Good balance of functionality vs complexity

3. **StandardFeatures** (40 shortcuts)
   - EssentialFeatures + textTransform + multilineNav
   - Adds text case changes and multi-line editing
   - Recommended for most applications

4. **FullFeatures** (65+ shortcuts)
   - All extended features enabled
   - Approaches C implementation feature parity
   - For power users and feature-complete applications

### Configuration Examples

```nim
# Initialize with specific feature set
initLinecross(StandardFeatures)
```

### Extended Shortcut Mappings (Nim)

**Word Movement** (when wordMovement enabled):
- `Alt-B` - Move back one word  
- `Alt-F` - Move forward one word

**Text Transformation** (when textTransform enabled):
- `Alt-U` - Uppercase current/following word
- `Alt-L` - Lowercase current/following word
- `Alt-C` - Capitalize current/following word

**Advanced Cut/Paste** (when advancedCutPaste enabled):
- `Ctrl-X` - Cut entire line
- `Ctrl-Y`, `Ctrl-V` - Paste from clipboard
- `Ctrl-W` - Cut from cursor to last space (replaces word movement)

**Advanced Editing** (when advancedEdit enabled):
- `Ctrl-T` - Transpose (swap) current and previous characters

## Development Workflow

### Key Shortcuts for Testing
- `F1`: Show help in edit mode (C only)
- `Ctrl-^`: Keyboard debug mode - shows key codes (C only)
- `Ctrl-R`: History search (C only), `F4`: Search with current input (C only)
- `F2`: Show history (C only), `F3`: Clear history (C only)
- `Tab`: Trigger completion
- `Ctrl-L`: Clear screen


### Platform Considerations
- Windows: Uses Console API for optimal performance
- Linux/Unix: ANSI escape sequences with terminal capability detection
- Special handling for different terminal types (vt100, xterm, etc.)

## Code Patterns

### Completion Implementation
```c/nim
// Register completion callback that matches input prefixes
// Add completions with optional help text and colors
// Support syntax hints for complex grammars
```

### History Integration
```c/nim  
// Save/load to files automatically
// Search with include/exclude patterns
// Duplicate removal and size limits
```

### Multi-line Editing
```c/nim
// Up/Down behavior depends on cursor position
// Ctrl/Alt+Up/Down for line navigation
// History shortcuts work at line boundaries
```

## Common Development Tasks

When working with this codebase:
- Test on multiple platforms when modifying core functionality
- Use keyboard debug mode (`Ctrl-^`) to verify key sequence handling (C only)
- Examples serve as integration tests - ensure they continue working
- **New**: Use `example_extended.nim` to test different feature configurations
- The Nim implementation now offers configurable feature sets from basic (15) to full (65+ shortcuts)
- Reference the keyboard shortcuts section and feature flag system above for capabilities