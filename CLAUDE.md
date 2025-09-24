# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Linecross is a cross-platform readline replacement library.

## Build Commands

### Check for compilation errors
```bash
nim check linecross.nim                 # Check library
```

## Architecture

### Core Components

**Nim Library (`linecross.nim`)**:
- Uses `std/terminal` module for cross-platform compatibility
- Strong typing and exception handling
- Simplified cursor positioning and color management

### Key Features
- Multi-line editing support with intelligent cursor movement
- Autocomplete system with customizable callbacks
- Color support for prompts

### Multi-line Editing Behavior

In multi-line mode, `Up`/`Down` key behavior is context-sensitive:
- **First line**: `Down` moves to next line, `Up` fetches history
- **Middle lines**: `Up`/`Down` move between lines
- **Last line (cursor not at end)**: `Up` moves up, `Down` fetches history  
- **Last line (cursor at end)**: `Up`/`Down` work as history shortcuts

Use `Ctrl-P`/`Ctrl-N` for consistent history navigation regardless of position.

