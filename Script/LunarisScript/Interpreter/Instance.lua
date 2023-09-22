local Error = require(script.Parent.Parent.Error)

local InstanceModule = {}
local Instan = {}

function InstanceModule.new(Klass)
	local Inst = setmetatable({}, {__index = Instan, __isinstance = true, __tostring = function() return Klass.Name .. " instance" end})
	
	Inst.Klass = Klass
	Inst.Fields = {}
	
	return Inst
end

function Instan:Get(Name)
	if self.Fields[Name.Lexeme] then
		return self.Fields[Name.Lexeme]
	end
	
	local Method = self.Klass:FindMethod(Name.Lexeme)
	if Method ~= nil then return Method:Bind(self) end
	
	Error.ErrorToken(Name, "Undefined property '" .. Name.Lexeme .. "'.")
end

function Instan:Set(Name, Value)
	self.Fields[Name.Lexeme] = Value
end

return InstanceModule