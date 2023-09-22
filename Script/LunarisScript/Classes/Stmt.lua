local Expr = require(script.Parent.Expr)

function Stringify(Object)
	if Object == nil then return "nil" end

	if tonumber(Object) then
		local Text = tostring(Object)

		if Text:reverse():sub(1,2):reverse() == ".0" then
			Text = Text:sub(1, #Text - 2)
		end

		return Text
	end

	return tostring(Object)
end

local StmtModule = {}
local Stmt = {}

function Stmt:new(o)
	o = o or {}

	setmetatable(o, self)
	self.__index = self

	return o
end

local Block = Stmt:new()
function Block:new(Statements)
	local o = Stmt.new(self)
	
	o.Statements = Statements
	
	return o
end

function Block:Accept(Visitor)
	return Visitor:visitBlockStmt(self)
end

local Class = Stmt:new()
function Class:new(Name, Superclass, Methods)
	local o = Stmt.new(self)

	o.Name = Name
	o.Superclass = Superclass
	o.Methods = Methods

	return o
end

function Class:Accept(Visitor)
	return Visitor:visitClassStmt(self)
end

local Expression = Stmt:new()
function Expression:new(Expr)
	local o = Stmt.new(self)

	o.Expression = Expr

	return o
end

function Expression:Accept(Visitor)
	return Visitor:visitExpressionStmt(self)
end

local Function = Stmt:new()
function Function:new(Name, Params, Body)
	local o = Stmt.new(self)
	
	o.Name = Name
	o.Params = Params
	o.Body = Body

	return o
end

function Function:Accept(Visitor)
	return Visitor:visitFunctionStmt(self)
end

local If = Stmt:new()
function If:new(Condition, ThenBranch, ElseBranch)
	local o = Stmt.new(self)

	o.Condition = Condition
	o.ThenBranch = ThenBranch
	o.ElseBranch = ElseBranch

	return o
end

function If:Accept(Visitor)
	return Visitor:visitIfStmt(self)
end

local Print = Stmt:new()
function Print:new(Expr)
	local o = Stmt.new(self)

	o.Expression = Expr

	return o
end

function Print:Accept(Visitor)
	return Visitor:visitPrintStmt(self)
end

local Return = Stmt:new()
function Return:new(Keyword, Value)
	local o = Stmt.new(self)

	o.Keyword = Keyword
	o.Value = Value

	return o
end

function Return:Accept(Visitor)
	return Visitor:visitReturnStmt(self)
end

local Var = Stmt:new()
function Var:new(Name, Initializer)
	local o = Stmt.new(self)
	
	o.Name = Name
	o.Initializer = Initializer

	return o
end

function Var:Accept(Visitor)
	return Visitor:visitVarStmt(self)
end

local While = Stmt:new()
function While:new(Condition, Body)
	local o = Stmt.new(self)

	o.Condition = Condition
	o.Body = Body

	return o
end

function While:Accept(Visitor)
	return Visitor:visitWhileStmt(self)
end

local Visitor = {}

function Visitor:new()
	local o = {}

	setmetatable(o, self)
	self.__index = self

	return o
end

function Visitor:visitBlockStmt(stmt)
end

function Visitor:visitClassStmt(stmt)
end

function Visitor:visitExpressionStmt(stmt)
end

function Visitor:visitFunctionStmt(stmt)
end

function Visitor:visitIfStmt(stmt)
end

function Visitor:visitPrintStmt(stmt)
end

function Visitor:visitReturnStmt(stmt)
end

function Visitor:visitVarStmt(stmt)
end

function Visitor:visitWhileStmt(stmt)
end

StmtModule.Visitor = Visitor
StmtModule.Block = Block
StmtModule.Class = Class
StmtModule.Expression = Expression
StmtModule.Function = Function
StmtModule.If = If
StmtModule.Print = Print
StmtModule.Return = Return
StmtModule.Var = Var
StmtModule.While = While

return StmtModule