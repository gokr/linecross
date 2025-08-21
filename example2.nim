import linecross, strutils

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
