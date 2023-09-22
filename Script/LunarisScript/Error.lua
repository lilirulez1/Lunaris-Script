local TokenTypes = require(script.Parent.Enums.TokenTypes)

local Error = {}

function Report(Line: number, Where: string, Message: string)
	error("\n[line " .. Line .. "] Error" .. Where .. ": " .. Message, 1)
end

function Error.ErrorLine(Line: number, Message: string)
	Report(Line, "", Message)
end

function Error.ErrorToken(Token, Message, Traceback)
	if Token.Type == TokenTypes.Eof then
		Report(Token.Line, " at end", Message)
	else
		Report(Token.Line, " at '" .. Token.Lexeme .. "'", Message)
	end
end

return Error