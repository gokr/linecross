# Linecross Examples

This directory contains focused examples demonstrating the features and capabilities of the linecross readline replacement library.

## Overview

Linecross is a cross-platform readline replacement library for Nim that provides:
- Basic readline functionality with editing and history
- Tab completion with customizable callbacks  
- Colored prompts and output
- Custom key bindings
- History management with custom storage backends

## Examples

### 1. `basic.nim` - Basic Usage

**Purpose**: Demonstrates the most fundamental linecross functionality.

**Features shown**:
- Simple readline input/output
- Basic text editing (arrow keys, backspace, delete)
- Enter to submit, Ctrl+C to exit
- Minimal setup required

**Run with**:
```bash
nim c -r basic.nim
```

**Best for**: Getting started, understanding the core API, simple applications.

---

### 2. `extended.nim` - Extended Features  

**Purpose**: Shows extended features and history management.

**Features shown**:
- History navigation (Up/Down arrows)
- Tab completion with custom callbacks
- History persistence (save/load)
- Extended feature documentation
- Standard readline shortcuts

**Run with**:
```bash
nim c -r extended.nim
```

**Best for**: Applications needing history, completion, and standard readline behavior.

---

### 3. `completion.nim` - Tab Completion

**Purpose**: Comprehensive demonstration of tab completion capabilities.

**Features shown**:
- Single-tab completion for unique matches
- Double-tab to show all possibilities
- Context-aware completions (SQL-like example)
- Multiple completion modes (file operations vs SQL syntax)
- Help text and descriptions

**Run with**:
```bash
nim c -r completion.nim
```

**Best for**: Applications with complex command structures, IDEs, shells, REPLs.

---

### 4. `advanced.nim` - Advanced Features

**Purpose**: Showcases the most advanced linecross capabilities.

**Features shown**:
- Custom history callbacks (custom storage backends)
- Colored prompts and output
- Custom key bindings (Ctrl+T example)
- History search and metadata
- Advanced completion with colored output
- Integration with external systems

**Run with**:
```bash
nim c -r advanced.nim
```

**Best for**: Complex applications, custom integrations, specialized requirements.

## Feature Comparison

| Feature | Basic | Extended | Completion | Advanced |
|---------|-------|----------|------------|----------|
| Basic readline | ✅ | ✅ | ✅ | ✅ |
| History navigation | ❌ | ✅ | ✅ | ✅ |
| Tab completion | ❌ | ✅ | ✅ | ✅ |
| Context-aware completion | ❌ | ❌ | ✅ | ✅ |
| Colored output | ❌ | ❌ | ❌ | ✅ |
| Custom key bindings | ❌ | ❌ | ❌ | ✅ |
| Custom history storage | ❌ | ❌ | ❌ | ✅ |
| History search | ❌ | ❌ | ❌ | ✅ |

## Usage Patterns

### Integrating into Your Application

1. **Start with `basic.nim`** to understand the core API
2. **Review `extended.nim`** for history and completion needs
3. **Study `completion.nim`** for complex completion requirements
4. **Examine `advanced.nim`** for specialized features

### Common Integration Steps

```nim
# 1. Import and initialize
import linecross
initLinecross(enableHistory = true)

# 2. Optional: Set up completion
proc myCompletion(buffer: string, cursorPos: int, isSecondTab: bool): string =
  # Your completion logic here
  return ""
registerCompletionCallback(myCompletion)

# 3. Optional: Load/save history
discard loadHistory("myapp.history")

# 4. Main input loop
while true:
  let input = readline("myapp> ")
  if input == "quit":
    break
  # Process input...

# 5. Optional: Save history on exit
discard saveHistory("myapp.history")
```

## API Reference

### Core Functions

- `initLinecross(enableHistory = true)` - Initialize the library
- `readline(prompt: string): string` - Get user input
- `addToHistory(line: string)` - Add entry to history
- `loadHistory(filename: string): bool` - Load history from file
- `saveHistory(filename: string): bool` - Save history to file
- `clearHistory()` - Clear all history

### Customization

- `setPromptColor(color, style)` - Set prompt color/style
- `registerCompletionCallback(callback)` - Set completion function
- `registerCustomKeyCallback(callback)` - Add custom key bindings
- `registerHistoryLoadCallback(callback)` - Custom history loading
- `registerHistorySaveCallback(callback)` - Custom history saving

### Completion Callback Signature

```nim
proc myCompletion(buffer: string, cursorPos: int, isSecondTab: bool): string
```

- `buffer`: Current input buffer
- `cursorPos`: Current cursor position  
- `isSecondTab`: `true` if this is the second tab press
- Return: Text to insert, or empty string to show completions

## Building and Running

All examples are designed to compile and run independently:

```bash
# Test compilation
nim check basic.nim
nim check extended.nim  
nim check completion.nim
nim check advanced.nim

# Run examples
nim c -r basic.nim
nim c -r extended.nim
nim c -r completion.nim
nim c -r advanced.nim
```

## Terminal Compatibility

The examples work on:
- Linux terminals (tested)
- macOS Terminal
- Windows Terminal  
- Most terminal emulators
- SSH sessions

## Next Steps

1. Choose the example that best matches your needs
2. Copy and adapt the relevant code patterns
3. Customize completion and history for your application
4. Test on your target platforms

For more information, see the main project documentation and the `linecross.nim` source file.