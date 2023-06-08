from code import InteractiveConsole
import sys

app = "Gobotics"

console = InteractiveConsole(locals = locals())

source_code = sys.argv[1]
# source_code = "app = 'Godot'; print(app)"
# print("Interactive")
console.runcode(source_code)
