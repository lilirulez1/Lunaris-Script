local Error = require(script.Parent.Parent.Error)

local EnvironmentModule = {}
local Environment = {}

function EnvironmentModule:new(Enclosing)
	return setmetatable({Values = {}, Enclosing = Enclosing}, {__index = Environment})
end

function Environment:Get(Name)
	local Value = self.Values[Name.Lexeme]
	
	if Value then
		return Value
	end
	
	if self.Enclosing ~= nil then return self.Enclosing:Get(Name) end
	
	Error.ErrorToken(Name, "Undefined variable '" .. Name.Lexeme .. "'.")
end

function Environment:Define(Name, Value)
	self.Values[Name] = Value
	
	return
end

function Environment:Assign(Name, Value)
	if self.Values[Name.Lexeme] then
		self.Values[Name.Lexeme] = Value
		
		return
	end
	
	if self.Enclosing ~= nil then
		self.Enclosing:Assign(Name, Value)
		
		return
	end

	Error.ErrorToken(Name, "Undefined variable '" .. Name.Lexeme .. "'.")
end

function Environment:AssignAt(Distance, Name, Value)
	self:Ancestor(Distance).Values[Name.Lexeme] = Value
end

function Environment:Ancestor(Distance)
	for i = 1, Distance do
		self = self.Enclosing
	end
	
	return self
end

function Environment:GetAt(Distance, Name)
	return self:Ancestor(Distance).Values[Name]
end

return EnvironmentModule