local Callable = require(script.Parent.Callable)
local EnvironmentModule = require(script.Parent.Parent.Classes.Environment)
local Return = require(script.Parent.Return)

local FnModule = {}

function FnModule.new(Declaration, Closure, IsInitializer)
	local Fn = Callable:new("<fn " .. Declaration.Name.Lexeme .. ">")
	
	Fn.Call = function(self, Interpreter, Arguments)
		local Environment = EnvironmentModule:new(Closure)
		
		for i = 1, #Declaration.Params do
			Environment:Define(Declaration.Params[i].Lexeme, Arguments[i])
		end
		
		local _, Success, Result = pcall(function()
			return Interpreter:ExecuteBlock(Declaration.Body, Environment)
		end)
		
		if not Success and getmetatable(Result).__isreturn then
			if IsInitializer then return Closure:GetAt(0, "this") end
			
			return Result.Value
		end
		
		if IsInitializer then
			return Closure:GetAt(0, "this")
		end
		
		return
	end
	
	Fn.Arity = function(self)
		return #Declaration.Params
	end
	
	Fn.Bind = function(self, Inst)
		local Environment = EnvironmentModule:new(Closure)
		Environment:Define("this", Inst)
		
		return FnModule.new(Declaration, Environment, IsInitializer)
	end
	
	return Fn
end

return FnModule