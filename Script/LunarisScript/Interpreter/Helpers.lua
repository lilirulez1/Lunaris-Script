local Error = require(script.Parent.Parent.Error)

local Helpers = {}

function Helpers.Stringify(Object)
	if Object == nil then return "nil" end

	if tonumber(Object) then
		local Text = tostring(Object)

		if Text:sub(#Text - 2, #Text) == ".0" then
			Text = Text:sub(0, #Text - 2)
		end

		return Text
	end

	return tostring(Object)
end

function Helpers.IsTruthy(Object)
	if Object == nil then return false end
	if typeof(Object) == "boolean" then return Object end

	return true
end

function Helpers.IsEqual(A, B)
	if A == nil and B == nil then return true end
	if A == nil then return false end

	return A == B
end

function Helpers.CheckNumberOperand(Operator, Operand)
	if tonumber(Operand) then return end

	Error.ErrorToken(Operator, "Operand must be a number.", "CheckNumberOperand")
end

function Helpers.CheckNumberOperands(Operator, Left, Right)
	if tonumber(Left) and tonumber(Right) then return end

	Error.ErrorToken(Operator, "Operands must be numbers.", "CheckNumberOperands")
end

return Helpers