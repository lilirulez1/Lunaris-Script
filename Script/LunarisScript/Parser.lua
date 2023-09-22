local Error = require(script.Parent.Error)

local TokenTypes = require(script.Parent.Enums.TokenTypes)
local ExpressionTypes = require(script.Parent.Enums.ExpressionTypes)

local Expr = require(script.Parent.Classes.Expr)
local Stmt = require(script.Parent.Classes.Stmt)

local ParserModule = {}
local Parser = {}

function ParserModule.new(Tokens: {[number]: {Type: number, Lexeme: string, Literal: string? | number?, Line: number}})
	local self = setmetatable({}, {__index = Parser})
	
	self.Tokens = Tokens
	self.Current = 1
	self.Statements = {}
	
	return self
end

-- << HELPERS -----------------------------------------------------------------------------------------------------------------

function Parser:Advance()
	if not self:IsAtEnd() then self.Current += 1 end
	return self:Previous()
end

function Parser:IsAtEnd()
	return self:Peek().Type == TokenTypes.Eof
end

function Parser:Consume(Type, Message)
	if self:Check(Type) == true then
		return self:Advance()
	end
	
	Error.ErrorToken(self:Peek(), Message, "Consume")
end

function Parser:Peek()
	return self.Tokens[self.Current]
end

function Parser:Match(...)
	for _, Type in {...} do
		if self:Check(Type) then
			self:Advance()
			
			return true
		end
	end
	
	return false
end

function Parser:Check(Type)
	if self:IsAtEnd() then return false end
	
	return self:Peek().Type == Type
end

function Parser:Previous()
	return self.Tokens[self.Current - 1]
end

-- >> HELPERS -----------------------------------------------------------------------------------------------------------------

-- << METHODS -----------------------------------------------------------------------------------------------------------------

-- Yes, I'm aware that having all the methods be like this is not ideal
-- If you have a better idea, message me (lili2 - Discord)

function Parser:Primary()
	if self:Match(TokenTypes.False) then return Expr.Literal:new(false) end
	if self:Match(TokenTypes.True) then return Expr.Literal:new(true) end
	if self:Match(TokenTypes.Nil) then return Expr.Literal:new(nil) end
	
	if self:Match(TokenTypes.Number, TokenTypes.String) then
		return Expr.Literal:new(self:Previous().Literal)
	end
	
	if self:Match(TokenTypes.Super) then
		local Keyword = self:Previous()
		
		self:Consume(TokenTypes.Dot, "Expected '.' after 'super'.")
		
		local Method = self:Consume(TokenTypes.Identifier, "Expected superclass method name.")
		
		return Expr.Super:new(Keyword, Method)
	end
	
	if self:Match(TokenTypes.This) then return Expr.This:new(self:Previous()) end
	
	if self:Match(TokenTypes.Identifier) then
		return Expr.Variable:new(self:Previous())
	end
	
	if self:Match(TokenTypes.LeftParen) then
		local Expression = self:Expression()
		
		self:Consume(TokenTypes.RightParen, "Expected ')' after expression.")
		
		return Expr.Grouping:new(Expression)
	end
	
	Error.ErrorToken(self:Peek(), "Expected expression.", "Primary")
end

function Parser:FinishCall(Callee)
	local Arguments = {}
	
	if not self:Check(TokenTypes.RightParen) then
		repeat
			table.insert(Arguments, self:Expression())
		until not self:Match(TokenTypes.Comma)
	end
	
	local Paren = self:Consume(TokenTypes.RightParen, "Expected ')' after arguments.")
	
	return Expr.Call:new(Callee, Paren, Arguments)
end

function Parser:Call()
	local Expression = self:Primary()
	
	while (true) do
		if self:Match(TokenTypes.LeftParen) then
			Expression = self:FinishCall(Expression)
		elseif self:Match(TokenTypes.Dot) then
			local Name = self:Consume(TokenTypes.Identifier, "Expected property name after '.'.")
			Expression = Expr.Get:new(Expression, Name)
		else
			break
		end
	end
	
	return Expression
end

function Parser:Unary()
	if self:Match(TokenTypes.Bang, TokenTypes.Minus) then
		local Operator = self:Previous()
		local Right = self:Unary()
		
		return Expr.Unary:new(Operator, Right)
	end
	
	return self:Call()
end

function Parser:Factor()
	local Expression = self:Unary()

	while self:Match(TokenTypes.Slash, TokenTypes.Star) do
		local Operator = self:Previous()
		local Right = self:Unary()

		Expression = Expr.Binary:new(Expression, Operator, Right)
	end

	return Expression
end

function Parser:Term()
	local Expression = self:Factor()

	while self:Match(TokenTypes.Minus, TokenTypes.Plus) do
		local Operator = self:Previous()
		local Right = self:Factor()

		Expression = Expr.Binary:new(Expression, Operator, Right)
	end

	return Expression
end

function Parser:Comparison()
	local Expression = self:Term()

	while self:Match(TokenTypes.Greater, TokenTypes.GreaterEqual, TokenTypes.Less, TokenTypes.LessEqual) do
		local Operator = self:Previous()
		local Right = self:Term()

		Expression = Expr.Binary:new(Expression, Operator, Right)
	end

	return Expression
end

function Parser:Equality()
	local Expression = self:Comparison()
	
	while self:Match(TokenTypes.BangEqual, TokenTypes.EqualEqual) do
		local Operator = self:Previous()
		local Right = self:Comparison()
		
		Expression = Expr.Binary:new(Expression, Operator, Right)
	end
	
	return Expression
end

function Parser:And()
	local Expression = self:Equality()
	
	while self:Match(TokenTypes.And) do
		local Operator = self:Previous()
		local Right = self:Equality()
		
		Expression = Expr.Logical:new(Expression, Operator, Right)
	end
	
	return Expression
end

function Parser:Or()
	local Expression = self:And()
	
	while self:Match(TokenTypes.Or) do
		local Operator = self:Previous()
		local Right = self:And()
		
		Expression = Expr.Logical:new(Expression, Operator, Right)
	end
	
	return Expression
end

function Parser:Assignment()
	local Expression = self:Or()
	
	if self:Match(TokenTypes.Equal) then
		local Equals = self:Previous()
		local Value = self:Assignment()
		
		if Expression.Type == ExpressionTypes.Variable then
			local Name = Expression.Name
			return Expr.Assign:new(Name, Value)
		elseif Expression.Type == ExpressionTypes.Get then
			return Expr.Set:new(Expression.Object, Expression.Name, Value)
		end
		
		Error.ErrorToken(Equals, "Invalid assignment target.", "Assignment")
	end
	
	return Expression
end

function Parser:Expression()
	return self:Assignment()
end

function Parser:Sync()
	self:Advance()
	
	while not self:IsAtEnd() do
		if self:Previous().Type == TokenTypes.SemiColon then return end

		local PeekType = self:Peek().Type
		
		if PeekType == TokenTypes.Class then
			return
		elseif PeekType == TokenTypes.Fn then
			return
		elseif PeekType == TokenTypes.Var then
			return
		elseif PeekType == TokenTypes.For then
			return
		elseif PeekType == TokenTypes.If then
			return
		elseif PeekType == TokenTypes.While then
			return
		elseif PeekType == TokenTypes.Print then
			return
		elseif PeekType == TokenTypes.Return then
			return
		end

		self:Advance()
	end
end

function Parser:ExpressionStatement()
	local Expression = self:Expression()
	
	self:Consume(TokenTypes.SemiColon, "Expected ';' after expression.")
	
	return Stmt.Expression:new(Expression)
end

function Parser:ReturnStatement()
	local Keyword = self:Previous()
	
	local Value
	
	if not self:Check(TokenTypes.SemiColon) then
		Value = self:Expression()
	end
	
	self:Consume(TokenTypes.SemiColon, "Expected ';' after return value.")
	
	return Stmt.Return:new(Keyword, Value)
end

function Parser:PrintStatement()
	local Value = self:Expression()
	
	self:Consume(TokenTypes.SemiColon, "Expected ';' after value.")
	
	return Stmt.Print:new(Value)
end

function Parser:Block()
	local Statements = {}
	
	while not self:Check(TokenTypes.RightBrace) and not self:IsAtEnd() do
		table.insert(Statements, self:Declaration())
	end
	
	self:Consume(TokenTypes.RightBrace, "Expected '}' after block.")
	
	return Statements
end

function Parser:IfStatement()
	self:Consume(TokenTypes.LeftParen, "Expected '(' after 'if'.")
	local Condition = self:Expression()
	self:Consume(TokenTypes.RightParen, "Expected ')' after if condition.")
	
	local ThenBranch = self:Statement()
	local ElseBranch = nil
	
	if self:Match(TokenTypes.Else) then
		ElseBranch = self:Statement()
	end
	
	return Stmt.If:new(Condition, ThenBranch, ElseBranch)
end

function Parser:WhileStatement()
	self:Consume(TokenTypes.LeftParen, "Expected '(' after 'while'.")
	local Condition = self:Expression()
	self:Consume(TokenTypes.RightParen, "Expected ')' after condition.")
	
	local Body = self:Statement()
	
	return Stmt.While:new(Condition, Body)
end

function Parser:ForStatement()
	self:Consume(TokenTypes.LeftParen, "Expected '(' after 'for'.")
	
	local Initializer
	
	if self:Match(TokenTypes.SemiColon) then
		Initializer = nil
	elseif self:Match(TokenTypes.Var) then
		Initializer = self:VarDeclaration()
	else
		Initializer = self:ExpressionStatement()
	end
	
	local Condition
	if not self:Check(TokenTypes.SemiColon) then
		Condition = self:Expression()
	end
	
	self:Consume(TokenTypes.SemiColon, "Expected ';' after loop condition.")
	
	local Increment = nil
	if not self:Check(TokenTypes.RightParen) then
		Increment = self:Expression()
	end
	
	self:Consume(TokenTypes.RightParen, "Expected ')' after for clauses.")
	
	local Body = self:Statement()
	
	if Increment ~= nil then
		table.insert(Body.Statements, Stmt.Expression:new(Increment))
	end
	
	if Condition == nil then Condition = Expr.Literal:new(true) end
	local WhileStatement = Stmt.While:new(Condition, Body)
	Body = WhileStatement
	
	if Initializer ~= nil then
		local BlockStatement = Stmt.Block:new({Initializer = Initializer, Body = Body})
		Body = BlockStatement
	end
	
	return Body
end

function Parser:Fn(Kind)
	local Name = self:Consume(TokenTypes.Identifier, "Expected " .. Kind .. " name.")
	self:Consume(TokenTypes.LeftParen, "Expected '(' after " .. Kind .. " name.")
	
	local Parameters = {}
	if not self:Check(TokenTypes.RightParen) then
		repeat
			if #Parameters >= 255 then
				Error.ErrorToken(self:Peek(), "Can't have more then 255 parameters.", "Function")
			end
			
			table.insert(Parameters, self:Consume(TokenTypes.Identifier, "Expected parameter name."))
		until not self:Match(TokenTypes.Comma)
	end
	
	self:Consume(TokenTypes.RightParen, "Expected ')' after parameters.")
	
	
	self:Consume(TokenTypes.LeftBrace, "Expected '{' before " .. Kind ..  " body.")
	
	local Body = self:Block()
	
	return Stmt.Function:new(Name, Parameters, Body)
end

function Parser:Statement()
	if self:Match(TokenTypes.For)       then return self:ForStatement()          end
	if self:Match(TokenTypes.If)        then return self:IfStatement()           end
	if self:Match(TokenTypes.Print)     then return self:PrintStatement()        end
	if self:Match(TokenTypes.Return)    then return self:ReturnStatement()       end
	if self:Match(TokenTypes.While)     then return self:WhileStatement()        end
	if self:Match(TokenTypes.LeftBrace) then return Stmt.Block:new(self:Block()) end
	
	return self:ExpressionStatement()
end

function Parser:VarDeclaration()
	local Name = self:Consume(TokenTypes.Identifier, "Expected variable name.")
	local Initializer = nil
	
	if self:Match(TokenTypes.Equal) then
		Initializer = self:Expression()
	end
	
	self:Consume(TokenTypes.SemiColon, "Expected ';' after variable declaration.")
	
	return Stmt.Var:new(Name, Initializer)
end

function Parser:ClassDeclaration()
	local Name = self:Consume(TokenTypes.Identifier, "Expected class name.")
	
	local Superclass
	if self:Match(TokenTypes.Less) then
		self:Consume(TokenTypes.Identifier, "Expected superclass name.")
		Superclass = Expr.Variable:new(self:Previous())
	end
	
	self:Consume(TokenTypes.LeftBrace, "Expected '{' before class body.")
	
	local Methods = {}
	while not self:Check(TokenTypes.RightBrace) and not self:IsAtEnd() do
		table.insert(Methods, self:Fn("method"))
	end
	
	self:Consume(TokenTypes.RightBrace, "Expected '}' after class body.")
	
	return Stmt.Class:new(Name, Superclass, Methods)
end

function Parser:Declaration()
	local Success, Result = pcall(function()
		if self:Match(TokenTypes.Class) then return self:ClassDeclaration() end
		if self:Match(TokenTypes.Fn)    then return self:Fn("function")     end
		if self:Match(TokenTypes.Var)   then return self:VarDeclaration()   end

		return self:Statement()
	end)
	
	if not Success then
		error(Result, 1)
	end
	
	return Result
end

-- >> METHODS -----------------------------------------------------------------------------------------------------------------

-- << Main >> --
function Parser:Parse()
	while not self:IsAtEnd() do
		local Success, Result = pcall(function()
			return self:Declaration()
		end)
		
		if Success then
			table.insert(self.Statements, Result)
		else
			return nil, Result:match("%[line %d+%] .*$")
		end
	end
	
	return self.Statements
end

return ParserModule