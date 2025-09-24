# Package

version       = "1.1"
author        = "Göran Krampe"
description   = "Linecross - cross-platform multiline readline replacement with history and completions"
license       = "MIT"
srcDir        = "."

# Dependencies

requires "nim >= 2.2.4"
requires "libclip" # For system clipboard integration (compile with -d:useSystemClipboard)


# Tasks

task test, "Run all tests":
  exec "nimble install -d"
  exec "testament --colors:on pattern 'tests/test_*.nim'"

task docs, "Generate documentation":
  exec "nim doc --project --index:on --git.url:https://github.com/gokr/linecross linecross.nim"

