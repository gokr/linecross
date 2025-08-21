# Package

version       = "1.0.0"
author        = "Göran Krampe"
description   = "Linecross - cross-platform readline replacement with configurable extended shortcuts"
license       = "MIT"
srcDir        = "."

# Dependencies

requires "nim >= 2.2.4"

# Optional dependencies - install separately if needed:
# nimble install nimclipboard  # For system clipboard integration (compile with -d:useSystemClipboard)

# Tasks

task test, "Run the test suite":
  exec "nim c -r example.nim"
  exec "nim c -r example2.nim"
  exec "nim c -r example_sql.nim"
  exec "nim c -r example_extended.nim"

task docs, "Generate documentation":
  exec "nim doc --project --index:on --git.url:https://github.com/gokr/linecross linecross.nim"

task clean, "Clean generated files":
  exec "rm -f example example2 example_sql example_extended"
  exec "rm -f *.exe"
  exec "rm -rf htmldocs/"