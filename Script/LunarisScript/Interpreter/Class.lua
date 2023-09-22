local Callable = require(script.Parent.Callable)
local InstanceClass = require(script.Parent.Instance)

local ClassModule = {}

function ClassModule.new(Name, Superclass, Methods)
	local Class = Callable:new(Name)
	
	getmetatable(Class).__isclass = true
	
	Class.Superclass = Superclass
	Class.Name = Name
	Class.Methods = Methods
	
	Class.Call = function(self, Interpreter, Arguments)
		local Inst = InstanceClass.new(Class)
		local Initializer = Class:FindMethod("init")
		if Initializer ~= nil then
			Initializer:Bind(Inst):Call(Interpreter, Arguments)
		end
		
		return Inst
	end
	
	Class.Arity = function(self)
		local Initializer = Class:FindMethod("init")
		
		if Initializer == nil then
			return 0
		end
		
		return Initializer:Arity()
	end
	
	Class.FindMethod = function(self, Name)
		if Class.Methods[Name] then
			return Class.Methods[Name]
		end
		
		if Superclass ~= nil then
			return Superclass:FindMethod(Name)
		end
		
		return
	end
	
	return Class
end

return ClassModule