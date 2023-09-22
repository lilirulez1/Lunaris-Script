local ScannerClass = require(script.Scanner)
local ParserClass = require(script.Parser)
local InterpreterClass = require(script.Interpreter)
local ResolverClass = require(script.Resolver)

local Interpreter = InterpreterClass:new()

local LunarisScript = {}

function LunarisScript:Run(SourceCode: string)
	local Scanner = ScannerClass.new(SourceCode)
	local Tokens, Error = Scanner:ScanTokens(false)
	
	if Error then
		print("This aint working rn, but you done f****d up.")
		return
	end
	
	local Parser = ParserClass.new(Tokens)
	local Statements, Error = Parser:Parse()
	
	if Error then
		print("\n  " .. Error .. "\n")
		return
	end
	
	local Resolver = ResolverClass.new(Interpreter)
	local Error = Resolver:ResolveStatements(Statements)
	
	if Error then
		print("\n  " .. Error .. "\n")
		return
	end
	
	local Error = Interpreter:Interpret(Statements)
	
	if Error then
		print("\n  " .. Error .. "\n")
		return
	end
end

return LunarisScript