local TokenTypes = require(script.Parent.Enums.TokenTypes)
local Token = require(script.Tokens)
local Error = require(script.Parent.Error)

-- << ENUMS -------------------------------------------------------------------------------------------------------------------

local Keywords = {
	["and"]    = TokenTypes.And,
	["class"]  = TokenTypes.Class,
	["else"]   = TokenTypes.Else,
	["false"]  = TokenTypes.False,
	["for"]    = TokenTypes.For,
	["fn"]     = TokenTypes.Fn,
	["if"]     = TokenTypes.If,
	["nil"]    = TokenTypes.Nil,
	["or"]     = TokenTypes.Or,
	--["print"]  = TokenTypes.Print, -- Uncomment to use print as a keyword | Eg. `print "Hello, World!";` instead of `print("Hello, World");` -*Function found in Interpreter/Builtins*-
	["return"] = TokenTypes.Return,
	["super"]  = TokenTypes.Super,
	["this"]   = TokenTypes.This,
	["true"]   = TokenTypes.True,
	["var"]    = TokenTypes.Var,
	["while"]  = TokenTypes.While,
}

-- >> ENUMS -------------------------------------------------------------------------------------------------------------------

local module = {}
local Lexers = {}

function module.new(SourceCode: string)
	local self = setmetatable({}, {__index = Lexers})

	self.SourceCode = SourceCode
	self.Characters = self.SourceCode:split("")

	self.Start   = 0
	self.Current = 0
	self.Line    = 1

	self.Tokens = {}

	return self
end


-- << HELPERS -----------------------------------------------------------------------------------------------------------------

function Lexers:Advance()
	self.Current += 1
	return self.Characters[self.Current]
end

function Lexers:IsAtEnd()
	return self.Current >= #self.Characters
end

function Lexers:AddToken(Type, Literal)
	local Text = self.SourceCode:sub(self.Start + 1, self.Current)
	table.insert(self.Tokens, Token.new(Type, Text, Literal, self.Line))
end

function Lexers:Match(Expected)
	if self:IsAtEnd() then return false end
	if self.Characters[self.Current + 1] ~= Expected then return false end

	self.Current += 1
	return true
end

function Lexers:Peek()
	if self:IsAtEnd() then return "\0" end

	return self.Characters[self.Current + 1]
end

function Lexers:PeekNext()
	if self.Current + 2 >= #self.Characters then return "\0" end
	return self.Characters[self.Current + 2]
end

function Lexers:IsDigit(Character)
	return Character >= "0" and Character <= "9"
end

-- >> HELPERS -----------------------------------------------------------------------------------------------------------------

-- << METHODS -----------------------------------------------------------------------------------------------------------------

function Lexers:String()
	while self:Peek() ~= '"' and not self:IsAtEnd() do
		if self:Peek() == "\n" then self.Line += 1 end
		self:Advance()
	end

	if self:IsAtEnd() then
		Error.ErrorToken(self.Line, "Unterminated string.")
		return
	end

	self:Advance()

	local Value = self.SourceCode:sub(self.Start + 2, self.Current - 1)
	self:AddToken(TokenTypes.String, Value)
end

function Lexers:Number()
	while self:IsDigit(self:Peek()) do self:Advance() end

	if self:Peek() == "." and self:IsDigit(self:PeekNext()) then
		self:Advance()

		while self:IsDigit(self:Peek()) do self:Advance() end
	end

	self:AddToken(TokenTypes.Number, tonumber(self.SourceCode:sub(self.Start + 1, self.Current)))
end

function Lexers:IsAlpha(Character)
	return Character:match("[A-Za-z]") or Character == "_"
end

function Lexers:IsAlphaNumeric(Character)
	return self:IsAlpha(Character) or self:IsDigit(Character)
end

function Lexers:Identifier()
	while self:IsAlphaNumeric(self:Peek()) do self:Advance() end

	local Text = self.SourceCode:sub(self.Start + 1, self.Current)
	local Type = Keywords[Text]

	if Type == nil then
		Type = TokenTypes.Identifier
	end

	self:AddToken(Type, nil)
end

-- >> METHODS -----------------------------------------------------------------------------------------------------------------

-- << MAIN >> --
function Lexers:ScanTokens(IncludeSpaces: boolean)
	local Success, Result = pcall(function()
		while not self:IsAtEnd() do
			self.Start = self.Current
			local Character = self:Advance()

			if Character == "(" then self:AddToken(TokenTypes.LeftParen)  continue end
			if Character == ")" then self:AddToken(TokenTypes.RightParen) continue end
			if Character == "{" then self:AddToken(TokenTypes.LeftBrace)  continue end
			if Character == "}" then self:AddToken(TokenTypes.RightBrace) continue end
			if Character == "," then self:AddToken(TokenTypes.Comma)      continue end
			if Character == "." then self:AddToken(TokenTypes.Dot)        continue end
			if Character == "+" then self:AddToken(TokenTypes.Plus)       continue end
			if Character == ";" then self:AddToken(TokenTypes.SemiColon)  continue end
			if Character == "*" then self:AddToken(TokenTypes.Star)       continue end
			if Character == "/" then self:AddToken(TokenTypes.Slash)      continue end

			if Character == "!" then
				self:AddToken((self:Match("=")) and TokenTypes.BangEqual or TokenTypes.Bang)
				continue
			end

			if Character == "=" then
				self:AddToken((self:Match("=")) and TokenTypes.EqualEqual or TokenTypes.Equal)
				continue
			end

			if Character == "<" then
				self:AddToken(self:Match("=") and TokenTypes.LessEqual or TokenTypes.Less)
				continue
			end

			if Character == ">" then
				self:AddToken(self:Match("=") and TokenTypes.GreaterEqual or TokenTypes.Greater)
				continue
			end

			if Character == "-" then
				if self:Match("-") then
					while self:Peek() ~= "\n" and not self:IsAtEnd() do self:Advance() end
				else
					self:AddToken(TokenTypes.Minus)
				end

				continue
			end

			if Character == " " or Character == "\r" or Character == "\t" then
				if not IncludeSpaces then
					continue
				end

				if Character == " " then
					self:AddToken(TokenTypes.Space)
				elseif Character == "\t" then
					self:AddToken(TokenTypes.Tab)
				end

				continue
			end

			if Character == "\n" then
				self.Line += 1
				continue
			end

			if Character == '"' then
				self:String()
				continue
			end

			if self:IsDigit(Character) then
				self:Number()
			elseif self:IsAlpha(Character) then
				self:Identifier()
			else
				Error.ErrorToken(self.Line, "Unexpected character.")
			end

			continue
		end

		table.insert(self.Tokens, Token.new(TokenTypes.Eof, "", nil, self.Line))
	end)
	
	if not Success then
		return nil, true
	end
	
	return self.Tokens
end

return module