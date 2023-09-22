local ExpressionTypes = require(script.Parent.Parent.Enums.ExpressionTypes)

local ExprModule = {}
local Expr = {}

function Expr:new(o)
	o = o or {}
	
	setmetatable(o, self)
	self.__index = self
	
	return o
end

local Assign = Expr:new()
function Assign:new(Name, Value)
	local o = Expr.new(self)

	o.Name = Name
	o.Value = Value
	o.Type = ExpressionTypes.Assign

	return o
end

function Assign:Accept(Visitor)
	return Visitor:visitAssignExpr(self)
end

local Binary = Expr:new()
function Binary:new(Left, Operator, Right)
	local o = Expr.new(self)

	o.Left = Left
	o.Operator = Operator
	o.Right = Right
	o.Type = ExpressionTypes.Binary

	return o
end

function Binary:Accept(Visitor)
	return Visitor:visitBinaryExpr(self)
end

local Call = Expr:new()
function Call:new(Callee, Paren, Arguments)
	local o = Expr.new(self)

	o.Callee = Callee
	o.Paren = Paren
	o.Arguments = Arguments
	o.Type = ExpressionTypes.Call

	return o
end

function Call:Accept(Visitor)
	return Visitor:visitCallExpr(self)
end

local Get = Expr:new()
function Get:new(Object, Name)
	local o = Expr.new(self)
	
	o.Object = Object
	o.Name = Name
	o.Type = ExpressionTypes.Get

	return o
end

function Get:Accept(Visitor)
	return Visitor:visitGetExpr(self)
end

local Grouping = Expr:new()
function Grouping:new(Expression)
	local o = Expr.new(self)
	
	o.Expression = Expression
	o.Type = ExpressionTypes.Grouping
	
	return o
end

function Grouping:Accept(Visitor)
	return Visitor:visitGroupingExpr(self)
end

local Literal = Expr:new()
function Literal:new(Value)
	local o = Expr.new(self)
	
	o.Value = Value
	o.Type = ExpressionTypes.Literal
	
	return o
end

function Literal:Accept(Visitor)
	return Visitor:visitLiteralExpr(self)
end

local Logical = Expr:new()
function Logical:new(Left, Operator, Right)
	local o = Expr.new(self)
	
	o.Left = Left
	o.Operator = Operator
	o.Right = Right
	o.Type = ExpressionTypes.Logical
	
	return o
end

function Logical:Accept(Visitor)
	return Visitor:visitLogicalExpr(self)
end

local Set = Expr:new()
function Set:new(Object, Name, Value)
	local o = Expr.new(self)
	
	o.Object = Object
	o.Name = Name
	o.Value = Value
	o.Type = ExpressionTypes.Set
	
	return o
end

function Set:Accept(Visitor)
	return Visitor:visitSetExpr(self)
end

local Super = Expr:new()
function Super:new(Keyword, Method)
	local o = Expr.new(self)
	
	o.Keyword = Keyword
	o.Method = Method
	o.Type = ExpressionTypes.Super
	
	return o
end

function Super:Accept(Visitor)
	return Visitor:visitSuperExpr(self)
end

local This = Expr:new()
function This:new(Keyword)
	local o = Expr.new(self)
	
	o.Keyword = Keyword
	o.Type = ExpressionTypes.This
	
	return o
end

function This:Accept(Visitor)
	return Visitor:visitThisExpr(self)
end

local Unary = Expr:new()
function Unary:new(Operator, Right)
	local o = Expr.new(self)
	
	o.Operator = Operator
	o.Right = Right
	o.Type = ExpressionTypes.Unary
	
	return o
end

function Unary:Accept(Visitor)
	return Visitor:visitUnaryExpr(self)
end

local Variable = Expr:new()
function Variable:new(Name)
	local o = Expr.new(self)
	
	o.Name = Name
	o.Type = ExpressionTypes.Variable
	
	return o
end

function Variable:Accept(Visitor)
	return Visitor:visitVariableExpr(self)
end

local Visitor = {}

function Visitor:new()
	local o = {}
	
	setmetatable(o, self)
	self.__index = self
	
	return o
end

function Visitor:visitAssignExpr(Expression)
end

function Visitor:visitBinaryExpr(Expression)
end

function Visitor:visitCallExpr(Expression)
end

function Visitor:visitGetExpr(Expression)
end

function Visitor:visitGroupingExpr(Expression)
end

function Visitor:visitLiteralExpr(Expression)
end

function Visitor:visitLogicalExpr(Expression)
end

function Visitor:visitSetExpr(Expression)
end

function Visitor:visitSuperExpr(Expression)
end

function Visitor:visitThisExpr(Expression)
end

function Visitor:visitUnaryExpr(Expression)
end

function Visitor:visitVariableExpr(expr)
end

ExprModule.Expr     = Expr
ExprModule.Assign   = Assign
ExprModule.Binary   = Binary
ExprModule.Call     = Call
ExprModule.Get      = Get
ExprModule.Grouping = Grouping
ExprModule.Literal  = Literal
ExprModule.Logical  = Logical
ExprModule.Set      = Set
ExprModule.Super    = Super
ExprModule.This     = This
ExprModule.Unary    = Unary
ExprModule.Variable = Variable
ExprModule.Visitor  = Visitor

return ExprModule