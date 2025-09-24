# Terminal Basics

A terminal is a text-based interface for interacting with your computer's operating system. It displays characters in a grid (rows and columns) and executes commands you type.

## Cursor Movement

The terminal maintains a cursor position (current row/column). You can move it using:

- Arrow keys (interactive)
- ANSI escape sequences (programmatic)

## ANSI Escape Codes

ANSI codes are special character sequences that control terminal behavior. They start with ESC (ASCII 27) followed by `[` and parameters.

### Common cursor movement codes:

- `\e[H` or `\e[1;1H` - Move to top-left (home)
- `\e[{row};{col}H` - Move to specific position
- `\e[{n}A` - Move up n lines
- `\e[{n}B` - Move down n lines
- `\e[{n}C` - Move right n columns
- `\e[{n}D` - Move left n columns

### Other useful codes:

- `\e[2J` - Clear entire screen
- `\e[K` - Clear current line
- `\e[s` - Save cursor position
- `\e[u` - Restore cursor position

### Colors:

- `\e[31m` - Red text
- `\e[32m` - Green text
- `\e[0m` - Reset to default

### Example in practice:

```bash
print("\e[2J\e[H")        # Clear screen, go to top
print("\e[31mError!\e[0m") # Red "Error!" text
print("\e[10;5HHello")     # "Hello" at row 10, column 5
```

The terminal interprets these sequences and moves the cursor or changes display properties accordingly.

## Save and Restore

Save and restore lets you temporarily store the cursor position and return to it later.

### How it works:

- `\e[s` - Save: Records current cursor position (row, column) in terminal's memory
- `\e[u` - Restore: Moves cursor back to the saved position

### Example:

```
Current position: row 5, col 10
\e[s              # Save position (5,10)
\e[20;1H          # Move to row 20, col 1
print("Status message")
\e[u              # Restore to position (5,10)
```

### Practical uses:

**Status updates without disrupting output:**
```bash
print("Processing files...")
print("\e[sFile 1 complete\e[u")  # Save, print status, restore
print("\e[sFile 2 complete\e[u")  # Overwrite previous status
```

**Creating HUDs or overlays:**
```bash
\e[s              # Save main cursor position
\e[1;1H           # Go to top-left
print("Status: OK")
\e[u              # Return to where you were typing
```

### Limitations:

- Only stores one position at a time
- Save is overwritten by the next `\e[s`
- Position is lost if terminal is resized or cleared

Some terminals support additional save/restore variants, but `\e[s` and `\e[u` are the most widely supported.

## Exact vs Relative Positioning

Both exist - you can use exact positioning or relative movement.

### Exact Positioning

- `\e[{row};{col}H` - Move to exact position
- `\e[{row};{col}f` - Same as H (alternative)

```bash
\e[10;25H    # Go exactly to row 10, column 25
\e[1;1H      # Go to top-left corner
```

### Relative Movement

- `\e[{n}A` - Up n lines
- `\e[{n}B` - Down n lines
- `\e[{n}C` - Right n columns
- `\e[{n}D` - Left n columns

```bash
\e[3A        # Move up 3 lines from current position
\e[5C        # Move right 5 columns from current position
```

### Key differences:

**Exact positioning:**
- Coordinates are 1-indexed (row 1, col 1 is top-left)
- Ignores current cursor location
- Bounds checking varies by terminal

**Relative movement:**
- Based on current cursor position
- Won't move beyond terminal boundaries
- n defaults to 1 if omitted (`\e[A` = `\e[1A`)

### Practical mixing:

```bash
\e[1;1H           # Exact: go to top-left
print("Header")
\e[2B             # Relative: down 2 lines
\e[10;1H          # Exact: row 10, column 1
\e[5C             # Relative: right 5 columns
```

Most terminal applications use a mix of both depending on whether they need precise placement or just want to adjust from the current position.

## Erasing

### Line-based erasing:

- `\e[K` or `\e[0K` - Clear from cursor to end of line
- `\e[1K` - Clear from beginning of line to cursor
- `\e[2K` - Clear entire current line

### Screen-based erasing:

- `\e[J` or `\e[0J` - Clear from cursor to end of screen
- `\e[1J` - Clear from beginning of screen to cursor
- `\e[2J` - Clear entire screen

## Newline Character Behavior

`\n` (newline) does two things:

1. Moves cursor down one row
2. Moves cursor to column 1 (beginning of new line)

```bash
Current position: row 5, col 10
print("Hello\n")
# Cursor now at: row 6, col 1
```

### Practical examples:

**Overwriting a line:**
```bash
print("Loading...")
\e[2K\e[1G        # Clear line, go to column 1
print("Complete!")
```

**Clearing status without newline:**
```bash
print("Processing", end="")  # No newline
\e[K                         # Clear rest of line
\e[1G                        # Go to start of line
print("Done!")
```

### Scrolling vs positioning:

- `\n` causes screen to scroll up if at bottom
- ANSI positioning (`\e[{row};{col}H`) doesn't scroll

### Terminal boundaries:

- Erasing respects terminal edges
- `\e[K` only clears to right edge of terminal
- Newlines at bottom edge scroll the entire screen up