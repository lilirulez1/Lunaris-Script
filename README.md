# ABOUT

LunarisScript is a lua interpretation of the language "Lox" by Robert Nystrom.

If you wish to publish your features to the main branch, please do either of the following:
	1. Message me (lili2) on discord
	2. Join the LunarisSDK discord server (https://discord.gg/NVWW9gjJuF), and upload your .rbxmx file to the #LunarisScript/features-fixes forum channel, following the format

# READ BEFORE USING

DO NOT USE THIS IN A PLACE THAT HAS ANY IMPORTANT STUFF
ONLY USE THIS PLUGIN IN A NEW, EMPTY PLACE AS IT LIKES TO CRASH
AND FOR SOME REASON, PLUGINS DONT HAVE SCRIPT TIMEOUTS

DO NOT USE FOR LOOPS UNTIL THEY ARE FIXED, THEY WILL CRASH YOUR STUDIO

# BUG FIXING / INFO

If you want to know more about how this interpreter works, or how you could go about bug fixing it, I have two resources for you:
	1. https://craftinginterpreters.com/a-tree-walk-interpreter.html
		- A step by step guide (that I followed to make this) explaining how to make a tree-walk interpeter.
		- All the stuff in this code and in the tutorial should share the same file names and variable names.

	2. https://github.com/munificent/craftinginterpreters/tree/01e6f5b8f3e5dfa65674c2f9cf4700d73ab41cf8/java/com/craftinginterpreters/lox
		- Contains the complete code for the interpeter this is based on.
		- Useful for bug fixing, so you can cross reference.
		- All the file names should be the same.

If you have discovered a bug and fixed a bug, post your .rbxmx file in the aforementioned channel so the interpreter can be patched.

## KNOWN BUGS

- For loops blow up you computer
- While loops inside of blocks do not work
