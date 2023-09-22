# ABOUT

LunarisScript is a lua interpretation of the language "Lox" by Robert Nystrom.

# READ BEFORE USING

Do not use this in a place that has any important stuff.
Only use this plugin in a new, empty place, as it likes to crash your studio.
For some reason, plugins don't have script timeouts.

DO NOT USE FOR LOOPS UNTIL THEY ARE FIXED, THEY WILL CRASH YOUR STUDIO

# INSTALLATION

1. Download the .rbxmx file
2. Make a **new** roblox place, and drag the .rbxmx into the window
3. Right click on the folder, and select `Save as Local Plugin...`
4. The Plugin will now appear in your Plugins tab

# BUG FIXING / INFO

If you want to know more about how this interpreter works, or how you could go about bug fixing it, I have two resources for you:
1. [Crafting Interpreters](https://craftinginterpreters.com/a-tree-walk-interpreter.html)
   - Step by step instructions on how the interpreter was made
   - Best if you want to add features, and understand how it works
3. [Github Repo](https://github.com/munificent/craftinginterpreters/tree/01e6f5b8f3e5dfa65674c2f9cf4700d73ab41cf8/java/com/craftinginterpreters/lox)
   - This contains the original code for the interpreter, written in Java
   - Best for bug fixing; Cross reference what could be causing issues with the original code

If you have discovered a bug and fixed a bug, post your .rbxmx file in the aforementioned channel so the interpreter can be patched.

## KNOWN BUGS

- For loops blow up you computer
- While loops inside of blocks do not work
