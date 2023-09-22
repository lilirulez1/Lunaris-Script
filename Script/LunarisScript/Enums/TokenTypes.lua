local TokenTypes = {
	LeftParen = 1, RightParen = 2, LeftBrace = 3, RightBrace = 4,
	Comma = 5, Dot = 6, Minus = 7, Plus = 8, SemiColon = 9, Slash = 10, Star = 11,
	
	Bang = 12, BangEqual = 13,
	Equal = 14, EqualEqual = 15,
	Greater = 16, GreaterEqual = 17,
	Less = 18, LessEqual = 19,
	
	Identifier = 20, String = 21, Number = 22,
	
	And = 23, Class = 24, Else = 25, False = 26, Fn = 27, For = 28, If = 29, Nil = 30, Or = 31,
	Print = 32, Return = 33, Super = 34, This = 35, True = 36, Var = 37, While = 38,
	
	Eof = 39, Space = 40, Tab = 41
}

return TokenTypes