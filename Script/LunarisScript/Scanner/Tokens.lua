local Tokens = {}

function GetTokenFromType(Type: number)
	for TokenType, Number in require(script.Parent.Parent.TokenTypes) do
		if Number == Type then
			return TokenType
		end
	end
end

function Tokens.new(Type, Lexeme, Literal, Line)
	local Token = setmetatable({
		Type = Type,
		Lexeme = Lexeme,
		Literal = Literal,
		Line = Line
	}, {
		__index = Tokens,
		__tostring = function()
			return GetTokenFromType(Type) .. " '" .. Lexeme .. "' " .. ((Literal == nil) and "" or Literal)
		end
	})
	
	return Token
end

return Tokens