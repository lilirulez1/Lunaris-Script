local ReturnModule = {}
local Return = {}

function ReturnModule.new(value)
	local self = setmetatable({}, {__index = Return, __isreturn = true})
	
	self.Value = value
	
	return self
end

return ReturnModule