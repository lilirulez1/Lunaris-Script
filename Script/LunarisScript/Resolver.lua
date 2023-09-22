local Error = require(script.Parent.Error)

local Expr = require(script.Parent.Classes.Expr)
local Stmt = require(script.Parent.Classes.Stmt)

-- << ENUMS -------------------------------------------------------------------------------------------------------------------

local FunctionType = {
	None = 0,
	Function = 1,
	Method = 2,
	Initializer = 3,
}

local ClassType = {
	None = 0,
	Class = 1,
	Subclass = 3
}

-- >> ENUMS -------------------------------------------------------------------------------------------------------------------

local ResolverModule = {}
local Resolver = {}

function ResolverModule.new(Interpreter)
	local Res = setmetatable({}, {__index = Resolver})

	Res.Interpreter = Interpreter
	Res.Scopes = {}
	Res.CurrentFunction = FunctionType.None
	Res.CurrentClass = ClassType.None
	
	-- << OVERRIDES ----------------------------------------------------------------------------------------------------------

	-- << IMPLEMENTS ------------------------------------------
	Res.StmtVisitor = Stmt.Visitor:new()
	Res.ExprVisitor = Expr.Visitor:new()
	-- >> IMPLEMENTS ------------------------------------------
	
	-- << STATEMENT OVERRIDES ---------------------------------------------------------------------------
	
	-- @Override
	Res.StmtVisitor.visitBlockStmt = function(self, Statement)
		Res:BeginScope()

		Res:ResolveStatements(Statement.Statements)

		Res:EndScope()

		return
	end
	
	-- @Override
	Res.StmtVisitor.visitClassStmt = function(self, Statement)
		local EnclosingClass = Res.CurrentClass
		Res.CurrentClass = ClassType.Class
		
		Res:Declare(Statement.Name)
		Res:Define(Statement.Name)
		
		if Statement.Superclass ~= nil and Statement.Name.Lexeme == Statement.Superclass.Name.Lexeme then
			Error.ErrorToken(Statement.Superclass.Name, "A class can't inherit from itself.")
		end
		
		if Statement.Superclass ~= nil then
			Res.CurrentClass = ClassType.Subclass
			Res:ResolveExpr(Statement.Superclass)
		end
		
		if Statement.Superclass ~= nil then
			Res:BeginScope()
			Res.Scopes[#Res.Scopes]["super"] = true
		end
		
		Res:BeginScope()
		Res.Scopes[#Res.Scopes]["this"] = true
		
		for _, Method in Statement.Methods do
			local Declaration = FunctionType.Method
			if Method.Name.Lexeme == "init" then
				Declaration = FunctionType.Initializer
			end
			
			Res:ResolveFunction(Method, Declaration)
		end
		
		Res:EndScope()
		
		if Statement.Superclass ~= nil then Res:EndScope() end
		
		Res.CurrentClass = EnclosingClass
		return
	end

	-- @Override
	Res.StmtVisitor.visitVarStmt = function(self, Statement)
		Res:Declare(Statement.Name)

		if Statement.Initializer ~= nil then
			Res:ResolveExpr(Statement.Initializer, "visitVarStmt")
		end

		Res:Define(Statement.Name)

		return
	end

	-- @Override
	Res.StmtVisitor.visitFunctionStmt = function(self, Statement)
		Res:Declare(Statement.Name)
		Res:Define(Statement.Name)

		Res:ResolveFunction(Statement, FunctionType.Function)
		return
	end

	-- @Override
	Res.StmtVisitor.visitExpressionStmt = function(self, Statement)
		Res:ResolveExpr(Statement.Expression, "visitIfStmt | Expression")
		return
	end

	-- @Override
	Res.StmtVisitor.visitIfStmt = function(self, Statement)
		Res:ResolveExpr(Statement.Condition, "visitIfStmt | Condition")
		Res:ResolveExpr(Statement.ThenBranch, "visitIfStmt | Then")
		
		if Statement.ElseBranch ~= nil then
			Res:ResolveExpr(Statement.ElseBranch, "visitIfStmt | Else")
		end
		
		return
	end

	-- @Override
	Res.StmtVisitor.visitPrintStmt = function(self, Statement)
		Res:ResolveExpr(Statement.Expression, "visitPrintStmt")
		
		return
	end

	-- @Override
	Res.StmtVisitor.visitReturnStmt = function(self, Statement)
		if Res.CurrentFunction == FunctionType.None then
			Error.ErrorToken(Statement.Keyword, "Can't return from top-level code.")
		end
		
		if Statement.Value ~= nil then
			if Res.CurrentFunction == FunctionType.Initializer then
				Error.ErrorToken(Statement.Keyword, "Can't return a value from an initializer.")
			end
			
			Res:ResolveExpr(Statement.Value, "visitReturnStmt | Value")
		end

		return
	end

	-- @Override
	Res.StmtVisitor.visitWhileStmt = function(self, Statement)
		Res:ResolveExpr(Statement.Condition, "visitWhileStmt | Condition")
		Res:ResolveExpr(Statement.Body, "visitWhileStmt | Body")
		
		return
	end

	-- >> STATEMENT OVERRIDES ---------------------------------------------------------------------------
	-- << EXPRESSION OVERRIDES---------------------------------------------------------------------------

	-- @Override
	Res.ExprVisitor.visitVariableExpr = function(self, Expression)
		if #Res.Scopes ~= 0 and Res.Scopes[#Res.Scopes][Expression.Name.Lexeme] == false then
			Error.ErrorToken(Expression.Name, "Can't read local variable in its own initializer.")
		end

		Res:ResolveLocal(Expression, Expression.Name)

		return
	end

	-- @Override
	Res.ExprVisitor.visitAssignExpr = function(self, Expression)
		Res:ResolveExpr(Expression.Value, "visitAssignExpr")
		Res:ResolveLocal(Expression, Expression.Name)

		return
	end

	-- @Override
	Res.ExprVisitor.visitBinaryExpr = function(self, Expression)
		Res:ResolveExpr(Expression.Left, "visitBinaryExpr | Left")
		Res:ResolveExpr(Expression.Right, "visitBinaryExpr | Right")
		
		return
	end

	-- @Override
	Res.ExprVisitor.visitCallExpr = function(self, Expression)
		Res:ResolveExpr(Expression.Callee, "visitCallExpr")
		
		for _, Argument in Expression.Arguments do
			Res:ResolveExpr(Argument, "visitCallExpr | Argument")
		end

		return
	end

	-- @Override
	Res.ExprVisitor.visitGetExpr = function(self, Expresion)
		Res:ResolveExpr(Expresion.Object, "visitGetExpr")
		
		return
	end

	-- @Override
	Res.ExprVisitor.visitGroupingExpr = function(self, Expression)
		Res:ResolveExpr(Expression.Expression, "visitGroupingExpr")

		return
	end

	-- @Override
	Res.ExprVisitor.visitLiteralExpr = function(self, Expression)
		return
	end

	-- @Override
	Res.ExprVisitor.visitLogicalExpr = function(self, Expression)
		Res:ResolveExpr(Expression.Left, "visitLogicalExpr | Left")
		Res:ResolveExpr(Expression.Right, "visitLogicalExpr | Right")
		
		return
	end

	-- @Override
	Res.ExprVisitor.visitSetExpr = function(self, Expression)
		Res:ResolveExpr(Expression.Value, "visitSetExpr | Value")
		Res:ResolveExpr(Expression.Object, "visitSetExpr | Object")
		
		return
	end

	-- @Override
	Res.ExprVisitor.visitThisExpr = function(self, Expression)
		if Res.CurrentClass == ClassType.None then
			Error.ErrorToken(Expression.Keyword, "Can't use 'this' outside of class.")
		end
		
		Res:ResolveLocal(Expression, Expression.Keyword)
		
		return
	end

	-- @Override
	Res.ExprVisitor.visitUnaryExpr = function(self, Expression)
		Res:ResolveExpr(Expression.Right, "visitUnaryExpr")
		
		return
	end

	-- @Override
	Res.ExprVisitor.visitSuperExpr = function(self, Expression)
		if Res.CurrentClass == ClassType.None then
			Error.ErrorToken(Expression.Keyword, "Can't use 'super' outside of class.")
		elseif Res.CurrentClass ~= ClassType.Subclass then
			Error.ErrorToken(Expression.Keyword, "Can't use 'super' in a class with no superclass.")
		end
		
		Res:ResolveLocal(Expression, Expression.Keyword)
		
		return
	end

	-- >> EXPRESSION OVERRIDES---------------------------------------------------------------------------

	return Res
end


-- << METHODS -----------------------------------------------------------------------------------------------------------------

function Resolver:ResolveFunction(Function, Type)
	local EnclosingFunction = self.CurrentFunction
	self.CurrentFunction = Type
	
	self:BeginScope()
	
	for _, Param in Function.Params do
		self:Declare(Param)
		self:Define(Param)
	end
	
	self:ResolveStatements(Function.Body, "ResolveFunction")
	
	self:EndScope()
	self.CurrentFunction = EnclosingFunction
end

function Resolver:ResolveLocal(Expression, Name)
	for i = #self.Scopes, 1, -1 do
		if self.Scopes[i][Name.Lexeme] then
			self.Interpreter:Resolve(Expression, #self.Scopes - i)

			return
		end
	end
end

function Resolver:Declare(Name)
	if #self.Scopes == 0 then return end

	local Scope = self.Scopes[#self.Scopes]
	
	if Scope[Name.Lexeme] then
		Error.ErrorToken(Name, "Already a variable with this name in this scope.")
	end

	Scope[Name.Lexeme] = false
end

function Resolver:Define(Name)
	if #self.Scopes == 0 then return end

	self.Scopes[#self.Scopes][Name.Lexeme] = true
end

function Resolver:BeginScope()
	table.insert(self.Scopes, {})
end

function Resolver:EndScope()
	table.remove(self.Scopes)
end

function Resolver:ResolveExpr(Expression, Debug)
	Expression:Accept(self.ExprVisitor)
end

function Resolver:ResolveStmt(Statement, Debug)
	Statement:Accept(self.StmtVisitor)
end

-- >> METHODS -----------------------------------------------------------------------------------------------------------------


-- << MAIN >> --
function Resolver:ResolveStatements(Statements)
	for _, Statement in Statements do
		local Success, Result = pcall(function()
			return self:ResolveStmt(Statement, "ResolveStatements")
		end)

		if not Success then
			return Result:match("%[line %d+%] .*$")
		end
	end
end

return ResolverModule