local TokenTypes = require(script.Parent.Enums.TokenTypes)
local ExpressionTypes = require(script.Parent.Enums.ExpressionTypes)
local Error = require(script.Parent.Error)

local Return = require(script.Return)
local Callable = require(script.Callable)
local Class = require(script.Class)
local Function = require(script.Function)
local Helpers = require(script.Helpers)

local Environment = require(script.Parent.Classes.Environment)
local Expr = require(script.Parent.Classes.Expr)
local Stmt = require(script.Parent.Classes.Stmt)

local InterpreterModule = {}
local Interpreter = {}

function InterpreterModule.new()
	local Inter = setmetatable({}, {__index = Interpreter})
	
	Inter.Globals = Environment:new()
	Inter.Environment = Inter.Globals
	Inter.Locals = {}
	
	-- << BUILTINS -----------------------------------------------------------------------------------------------------------
	local PrintBuiltin = Callable:new("<native fn>")
	PrintBuiltin.Arity = function(self)
		return 1
	end
	
	PrintBuiltin.Call = function(self, Interpreter, Arguments)
		local Value = Arguments[1]
		
		local Success, Result = pcall(function()
			return loadstring('return "' .. Helpers.Stringify(Value) .. '"')()
		end)

		if Success then
			print(Result)
		end
	end
	
	local ClockBuiltin = Callable:new("<native fn>")
	ClockBuiltin.Arity = function(self)
		return 0
	end
	
	ClockBuiltin.Call = function(self, Interpreter, Arguments)
		return os.clock()
	end
	
	Inter.Globals:Define("clock", ClockBuiltin)
	Inter.Globals:Define("print", PrintBuiltin)
	
	-- >> BUILTINS -----------------------------------------------------------------------------------------------------------

	-- << OVERRIDES ----------------------------------------------------------------------------------------------------------
	
	-- << IMPLEMENTS ------------------------------------------
	Inter.ExprVisitor = Expr.Visitor:new()
	Inter.StmtVisitor = Stmt.Visitor:new()
	-- >> IMPLEMENTS ------------------------------------------

	-- << EXPRESSION OVERRIDES --------------------------------------------------------------------------
	
	-- @Override
	Inter.ExprVisitor.visitLiteralExpr = function(self, Expression)
		return Expression.Value
	end

	-- @Override
	Inter.ExprVisitor.visitLogicalExpr = function(self, Expression)
		local Left = Inter:Evaluate(Expression.Left, "Logical | Left")
		
		if Expression.Operator.Type == TokenTypes.Or then
			if Helpers.IsTruthy(Left) then return Left end
		else
			if not Helpers.IsTruthy(Left) then return Left end
		end
		
		return Inter:Evaluate(Expression.Right, "Logical")
	end

	-- @Override
	Inter.ExprVisitor.visitGroupingExpr = function(self, Expression)
		return Inter:Evaluate(Expression.Expression, "Grouping")
	end

	-- @Override
	Inter.ExprVisitor.visitUnaryExpr = function(self, Expression)
		local Right = Inter:Evaluate(Expression.Right, "Unary")
		
		if Expression.Operator.Type == TokenTypes.Minus then
			Helpers.CheckNumberOperand(Expression.Operator, Right)
			return -tonumber(Right)
		elseif Expression.Operator.Type == TokenTypes.Bang then
			return not Helpers.IsTruthy(Right)
		end
		
		return nil
	end

	-- @Override
	Inter.ExprVisitor.visitBinaryExpr = function(self, Expression)
		local Left  = Inter:Evaluate(Expression.Left, "Binary | Left")
		local Right = Inter:Evaluate(Expression.Right, "Binary | Right")
		
		local Operator = Expression.Operator.Type
		
		if     Operator == TokenTypes.Greater      then
			Helpers.CheckNumberOperands(Expression.Operator, Left, Right)
			return tonumber(Left) >  tonumber(Right)
		elseif Operator == TokenTypes.GreaterEqual then
			Helpers.CheckNumberOperands(Expression.Operator, Left, Right)
			return tonumber(Left) >= tonumber(Right)
		elseif Operator == TokenTypes.Less         then
			Helpers.CheckNumberOperands(Expression.Operator, Left, Right)
			return tonumber(Left) <  tonumber(Right)
		elseif Operator == TokenTypes.LessEqual    then
			Helpers.CheckNumberOperands(Expression.Operator, Left, Right)
			return tonumber(Left) <= tonumber(Right)
		elseif Operator == TokenTypes.Minus        then
			Helpers.CheckNumberOperands(Expression.Operator, Left, Right)
			return tonumber(Left) - tonumber(Right)
		elseif Operator == TokenTypes.Plus         then
			if tonumber(Left) and tonumber(Right) then
				return tonumber(Left) + tonumber(Right)
			end
			
			if tostring(Left) and tostring(Right) then
				return tostring(Left) .. tostring(Right)
			end
			
			Error.ErrorToken(Expression.Operator, "Operands must be two numbers, or numbers and strings.", "Plus")
		elseif Operator == TokenTypes.Slash        then
			Helpers.CheckNumberOperands(Expression.Operator, Left, Right)
			return tonumber(Left) / tonumber(Right)
		elseif Operator == TokenTypes.Star         then
			Helpers.CheckNumberOperands(Expression.Operator, Left, Right)
			return tonumber(Left) * tonumber(Right)
		elseif Operator == TokenTypes.BangEqual    then
			return not Helpers.IsEqual(Left, Right)
		elseif Operator == TokenTypes.EqualEqual   then
			return     Helpers.IsEqual(Left, Right)
		end
	end

	-- @Override
	Inter.ExprVisitor.visitCallExpr = function(self, Expression)
		local Callee = Inter:Evaluate(Expression.Callee, "Call")
		
		local Arguments = {}
		
		for _, Argument in Expression.Arguments do
			table.insert(Arguments, Inter:Evaluate(Argument, "Call"))
		end
		
		if Expression.Type ~= ExpressionTypes.Call then
			Error.ErrorToken(Expression.Paren, "Can only call functions and classes.", "visitCallExpr | Comparison")
		end
		
		if #Arguments ~= Callee:Arity() then
			Error.ErrorToken(Expression.Paren, "Expected " .. Callee:Arity() .. " arguments but got " .. #Arguments .. ".", "visitCallExpr | Arity")
		end
		
		return Callee:Call(Inter, Arguments)
	end

	-- @Override
	Inter.ExprVisitor.visitGetExpr = function(self, Expression)
		local Object = Inter:Evaluate(Expression.Object)
		
		if getmetatable(Object).__isinstance then
			return Object:Get(Expression.Name)
		end
		
		Error.ErrorToken(Expression.Name, "Only instances have properties.", "visitGetExpr")
	end

	-- @Override
	Inter.ExprVisitor.visitVariableExpr = function(self, Expression)
		return Inter:LookUpVariable(Expression.Name, Expression)
	end

	-- @Override
	Inter.ExprVisitor.visitAssignExpr = function(self, Expression)
		local Value = Inter:Evaluate(Expression.Value, "Assign")
		
		local Distance = Inter.Locals[Expression]
		
		if Distance ~= nil then
			Inter.Environment:AssignAt(Distance, Expression.Name, Value)
		else
			Inter.Globals:Assign(Expression.Name, Value)
		end
		
		return Value
	end

	-- @Override
	Inter.ExprVisitor.visitSetExpr = function(self, Expression)
		local Object = Inter:Evaluate(Expression.Object)
		
		if not getmetatable(Object).__isinstance then
			Error.ErrorToken(Expression.Name, "Only instances have fields.", "visitSetExpr")
		end
		
		local Value = Inter:Evaluate(Expression.Value)
		
		Object:Set(Expression.Name, Value)
		
		return Value
	end

	-- @Override
	Inter.ExprVisitor.visitSuperExpr = function(self, Expression)
		local Distance = Inter.Locals[Expression]
		
		local Superclass = Inter.Environment:GetAt(Distance, "super")
		
		local Object = Inter.Environment:GetAt(Distance - 1, "this")
		
		local Method = Superclass:FindMethod(Expression.Method.Lexeme)
		
		if Method == nil then
			Error.ErrorToken(Expression.Method, "Undefined property '" .. Expression.Method.Lexeme .. "'.", "visitSuperExpr")
		end
		
		return Method:Bind(Object)
	end

	-- @Override
	Inter.ExprVisitor.visitThisExpr = function(self, Expression)
		return Inter:LookUpVariable(Expression.Keyword, Expression)
	end
	

	-- >> EXPRESSION OVERRIDES --------------------------------------------------------------------------
	-- << STATEMENT OVERRIDES ---------------------------------------------------------------------------

	-- @Override
	Inter.StmtVisitor.visitExpressionStmt = function(self, Statement)
		Inter:Evaluate(Statement.Expression, "Expression")
		
		return
	end

	-- @Override
	Inter.StmtVisitor.visitFunctionStmt = function(self, Statement)
		local Fn = Function.new(Statement, Inter.Environment, false)
		
		Inter.Environment:Define(Statement.Name.Lexeme, Fn)
		
		return
	end

	-- @Override
	Inter.StmtVisitor.visitIfStmt = function(self, Statement)
		if Helpers.IsTruthy(Inter:Evaluate(Statement.Condition, "If")) then
			Inter:Execute(Statement.ThenBranch)
		elseif Statement.ElseBranch ~= nil then
			Inter:Execute(Statement.ElseBranch)
		end
		
		return nil
	end

	-- @Override
	Inter.StmtVisitor.visitPrintStmt = function(self, Statement)
		local Value = Inter:Evaluate(Statement.Expression, "Print")
		print(Helpers.Stringify(Value))
		
		return
	end

	-- @Override
	Inter.StmtVisitor.visitReturnStmt = function(self, Statement)
		local Value
		
		if Statement.Value ~= nil then Value = Inter:Evaluate(Statement.Value, "Return 232") end
		
		error(Return.new(Value))
	end

	-- @Override
	Inter.StmtVisitor.visitVarStmt = function(self, Statement)
		local Value = nil
		
		if Statement.Initializer ~= nil then
			Value = Inter:Evaluate(Statement.Initializer, "Var")
		end
		
		Inter.Environment:Define(Statement.Name.Lexeme, Value)

		return
	end
	
	-- @Override
	Inter.StmtVisitor.visitWhileStmt = function(self, Statement)
		while Helpers.IsTruthy(Inter:Evaluate(Statement.Condition, "While")) do
			Inter:Execute(Statement.Body)
		end
		
		return
	end

	-- @Override
	Inter.StmtVisitor.visitBlockStmt = function(self, Statement)
		Inter:ExecuteBlock(Statement.Statements, Environment:new(Inter.Environment))
		return
	end

	-- @Override
	Inter.StmtVisitor.visitClassStmt = function(self, Statement)
		local Superclass = nil
		
		if Statement.Superclass ~= nil then
			Superclass = Inter:Evaluate(Statement.Superclass)
			
			if not getmetatable(Superclass).__isclass then
				Error.ErrorToken(Statement.Superclass.Name, "Superclass must be a class.", "visitClassStmt")
			end
		end
		
		Inter.Environment:Define(Statement.Name.Lexeme, true)
		
		if Statement.Superclass ~= nil then
			Inter.Environment = Environment:new(Inter.Environment)
			Inter.Environment:Define("super", Superclass)
		end
		
		local Methods = {}
		for _, Method in Statement.Methods do
			local Func = Function.new(Method, Inter.Environment, (Method.Name.Lexeme == "init"))
			Methods[Method.Name.Lexeme] = Func
		end
		
		local Klass = Class.new(Statement.Name.Lexeme, Superclass, Methods)
		Inter.Environment:Assign(Statement.Name, Klass)
		
		if Superclass ~= nil then
			Inter.Environment = Inter.Environment.Enclosing
		end
		
		Inter.Environment:Assign(Statement.Name, Klass)
		return
	end
	
	-- >> STATEMENT OVERRIDES ---------------------------------------------------------------------------

	-- >> OVERRIDES ----------------------------------------------------------------------------------------------------------
	
	return Inter
end

-- << METHODS -----------------------------------------------------------------------------------------------------------------

function Interpreter:LookUpVariable(Name, Expression)
	local Distance = self.Locals[Expression]
	
	if Distance ~= nil then
		return self.Environment:GetAt(Distance, Name.Lexeme)
	else
		return self.Globals:Get(Name)
	end
end

function Interpreter:ExecuteBlock(Statements, Environment)
	local Previous = self.Environment
	
	local Success, Result = pcall(function()
		self.Environment = Environment
		
		for _, Statement in Statements do
			self:Execute(Statement)
		end
	end)
	
	self.Environment = Previous
	
	return Success, Result
end

function Interpreter:Evaluate(Expression, Debug)
	return Expression:Accept(self.ExprVisitor)
end

function Interpreter:Execute(Statement)
	Statement:Accept(self.StmtVisitor)
end

function Interpreter:Resolve(Expression, Depth)
	self.Locals[Expression] = Depth
end

-- >> METHODS -----------------------------------------------------------------------------------------------------------------

-- << MAIN >> --

function Interpreter:Interpret(Statements)
	for _, Statement in Statements do
		local Success, Result = pcall(function()
			return self:Execute(Statement)
		end)

		if not Success then
			return Result:match("%[line %d+%] .*$")
		end
	end
end

return InterpreterModule