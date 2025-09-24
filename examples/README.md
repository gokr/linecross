# Enhanced Linecross Examples

This directory contains demonstration programs for the enhanced linecross persistent input area functionality. These examples show how the new features solve cursor positioning issues and provide a foundation for better terminal interfaces.

## Examples

### 1. `simple_demo.nim` - Basic Usage
A minimal example showing the core persistent input area functionality.

**Features demonstrated:**
- Entering/exiting persistent mode
- Displaying content above input with `printAboveInput()`
- Temporary content below input with `printBelow()`
- Basic paging for long content

**Run with:**
```bash
cd linecross/examples
nim c -r simple_demo.nim
```

### 2. `comparison_demo.nim` - Before vs After
Shows the difference between normal mode (old behavior) and enhanced mode.

**Features demonstrated:**
- Side-by-side comparison of old vs new behavior
- How tables disrupted cursor positioning before
- How persistent input area solves the problem
- Clear benefits of the enhancement

**Run with:**
```bash
nim c -r comparison_demo.nim
```

### 3. `demo_persistent_mode.nim` - Comprehensive Demo
Full demonstration of all persistent input area features.

**Features demonstrated:**
- All four demo modes:
  1. Basic persistent mode with table display
  2. Automatic paging functionality
  3. Temporary display below input
  4. Interactive session (Niffler simulation)
- Complete feature set usage
- Real-world usage scenarios

**Run with:**
```bash
nim c -r demo_persistent_mode.nim
```

## The Problem These Examples Solve

### Original Issue
When using Nancy tables in Niffler CLI (like for `/conv` command output), the cursor would get stuck in the bottom-right corner after displaying the table instead of returning to the prompt. This made the interface unusable.

### Enhanced Solution
The persistent input area provides:

1. **Fixed Input Area**: Input prompt stays at the bottom of the terminal
2. **Output Above**: All command output appears above the input area
3. **Cursor Stability**: Cursor positioning is never disrupted
4. **Automatic Paging**: Long content is paginated automatically
5. **Temporary Display**: Completions can be shown below input temporarily

## Key Functions Demonstrated

### Core Functions
- `enterPersistentMode()` - Enable persistent input area
- `exitPersistentMode()` - Return to normal behavior
- `printAboveInput(content)` - Display content above input
- `printBelow(content)` - Show temporary content below input
- `clearBelow()` - Clear temporary content

### Configuration
- `setPersistentModeConfig()` - Configure input area behavior
- `isInPersistentMode()` - Check current mode

## Running the Examples

All examples require the enhanced linecross to be compiled first:

```bash
# From the linecross directory
nim c linecross.nim

# Then run any example
cd examples
nim c -r simple_demo.nim
nim c -r comparison_demo.nim
nim c -r demo_persistent_mode.nim
```

## Integration with Niffler

These examples show exactly how Niffler can integrate the enhanced linecross:

1. **Enter persistent mode** when starting interactive session
2. **Use `printAboveInput()`** for command output (including Nancy tables)
3. **Use `printBelow()`** for completions and temporary help
4. **Exit persistent mode** when shutting down

This will solve the cursor positioning issue while providing a much more polished user experience similar to modern IDEs and advanced terminal applications.

## Terminal Compatibility

The enhanced linecross uses standard ANSI escape sequences and should work on:
- Most Linux terminals (tested)
- macOS Terminal
- Windows Terminal
- Most terminal emulators
- SSH sessions

The implementation includes fallbacks for terminals with limited capabilities.