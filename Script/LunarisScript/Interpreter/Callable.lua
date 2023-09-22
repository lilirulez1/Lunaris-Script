local ExpressionTypes = require(script.Parent.Parent.Enums.ExpressionTypes)

local CallableModule = {}

function CallableModule:new(Type)
	return setmetatable({}, {__index = CallableModule, __tostring = function() return Type end})
end

function CallableModule:Arity()
	return
end

function CallableModule:Call(Interpreter, Arguments)
	return "This shouldn't happen"
end

return CallableModule