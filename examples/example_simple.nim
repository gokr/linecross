## Simple example for linecross
## Tests basic functionality: prompt display, editing, multiline support

import linecross

proc main() =
  initLinecross()
  
  echo "Linecross2 Simple Example"
  echo "========================"
  echo "Basic editing test - type some text, use arrows, backspace, etc."
  echo "Press Ctrl+C to exit, Enter to submit line"
  echo ""
  
  while true:
    let input = readline("simple> ")
    if input.len == 0:
      break
    echo "You entered: ", input

when isMainModule:
  main()