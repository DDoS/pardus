module pardus.syntax.token;

import std.format : format;
import std.conv : to, ConvOverflowException;

import pardus.syntax.chars;
import pardus.syntax.source;

enum TokenKind {
    COLON,
    SEMICOLON,

    IDENTIFIER,

    KEYWORD_VAR,
    KEYWORD_IF,
    KEYWORD_ELSE,
    KEYWORD_WHILE,
    KEYWORD_DO,

    OPERATOR_PLUS,
    OPERATOR_MINUS,
    OPERATOR_TIMES,
    OPERATOR_DIVIDE,
    OPERATOR_ASSIGN,
    OPERATOR_OPEN_PARENTHESIS,
    OPERATOR_CLOSE_PARENTHESIS,

    LITERAL_INT,
    LITERAL_FLOAT,
    LITERAL_STRING,

    EOF
}

interface Token {
    @property size_t start();
    @property size_t end();
    @property void start(size_t start);
    @property void end(size_t end);
    string getSource();
    TokenKind kind();
    string toString();
}

private template FixedToken(TokenKind _kind, string source) if (source.length > 0) {
    private class FixedToken : Token {
        this(size_t start) {
            _start = start;
            _end = start + source.length - 1;
        }

        override string getSource() {
            return source;
        }

        @property override TokenKind kind() {
            return _kind;
        }

        mixin sourceIndexFields;

        override string toString() {
            return _kind.to!string();
        }
    }
}

alias Colon = FixedToken!(TokenKind.COLON, ":");
alias Semicolon = FixedToken!(TokenKind.SEMICOLON, ";");

alias KeywordVar = FixedToken!(TokenKind.KEYWORD_VAR, "var");
alias KeywordIf = FixedToken!(TokenKind.KEYWORD_IF, "if");
alias KeywordElse = FixedToken!(TokenKind.KEYWORD_ELSE, "else");
alias KeywordWhile = FixedToken!(TokenKind.KEYWORD_WHILE, "while");
alias KeywordDo = FixedToken!(TokenKind.KEYWORD_DO, "do");

alias OperatorPlus = FixedToken!(TokenKind.OPERATOR_PLUS, "+");
alias OperatorMinus = FixedToken!(TokenKind.OPERATOR_MINUS, "-");
alias OperatorTimes = FixedToken!(TokenKind.OPERATOR_TIMES, "*");
alias OperatorDivide = FixedToken!(TokenKind.OPERATOR_DIVIDE, "/");
alias OperatorAssign = FixedToken!(TokenKind.OPERATOR_ASSIGN, "=");
alias OperatorOpenParenthesis = FixedToken!(TokenKind.OPERATOR_OPEN_PARENTHESIS, "(");
alias OperatorCloseParenthesis = FixedToken!(TokenKind.OPERATOR_CLOSE_PARENTHESIS, ")");

class Identifier : Token {
    private string source;

    this(string source, size_t start) {
        this.source = source;
        _start = start;
        _end = start + source.length - 1;
    }

    override string getSource() {
        return source;
    }

    @property override TokenKind kind() {
        return TokenKind.IDENTIFIER;
    }

    mixin sourceIndexFields;

    override string toString() {
        return "%s(%s)".format(kind, source);
    }
}

class LiteralString : Token {
    private string source;

    this(string source, size_t start) {
        this.source = source;
        _start = start;
        _end = start + source.length - 1;
    }

    override string getSource() {
        return source;
    }

    @property override TokenKind kind() {
        return TokenKind.LITERAL_STRING;
    }

    mixin sourceIndexFields;

    string getValue() {
        auto length = source.length;
        if (length < 2) {
            throw new Error("String is missing enclosing quotes");
        }
        if (source[0] != '"') {
            throw new Error("String is missing beginning quote");
        }
        auto value = source[1 .. length - 1].decodeStringContent();
        if (source[length - 1] != '"') {
            throw new Error("String is missing ending quote");
        }
        return value;
    }

    override string toString() {
        return "%s(%s)".format(kind, source);
    }

    unittest {
        auto a = new LiteralString("\"hel\\\"lo\"", 0);
        assert(a.getValue() == "hel\"lo");
        auto b = new LiteralString("\"hel\\\\lo\"", 0);
        assert(b.getValue() == "hel\\lo");
        auto c = new LiteralString("\"hel\\nlo\"", 0);
        assert(c.getValue() == "hel\nlo");
        auto d = new LiteralString("\"hel\\r\\f\\vlo\"", 0);
        assert(d.getValue() == "hel\r\f\vlo");
    }
}

private string decodeStringContent(string data) {
    char[] buffer = [];
    buffer.reserve(64);
    for (size_t i = 0; i < data.length; ) {
        char c = data[i];
        i += 1;
        if (c == '\\') {
            c = data[i];
            i += 1;
            c = c.decodeCharEscape();
        }
        buffer ~= c;
    }
    return buffer.idup;
}

class LiteralInt : Token {
    private string source;

    this(string source, size_t start) {
        this.source = source;
        _start = start;
        _end = start + source.length - 1;
    }

    override string getSource() {
        return source;
    }

    @property override TokenKind kind() {
        return TokenKind.LITERAL_INT;
    }

    mixin sourceIndexFields;

    int getValue(out bool overflow) {
        try {
            overflow = false;
            return source.to!int(10);
        } catch (ConvOverflowException) {
            overflow = true;
            return -1;
        }
    }

    override string toString() {
        return "%s(%s)".format(kind, source);
    }

    unittest {
        bool overflow;
        auto a = new LiteralInt("42432", 0);
        assert(a.getValue(overflow) == 42432);
        assert(!overflow);
        auto b = new LiteralInt("9223372036854775808", 0);
        b.getValue(overflow);
        assert(overflow);
    }
}

class LiteralFloat : Token {
    private string source;

    this(string source, size_t start) {
        this.source = source;
        _start = start;
        _end = start + source.length - 1;
    }

    override string getSource() {
        return source;
    }

    @property override TokenKind kind() {
        return TokenKind.LITERAL_FLOAT;
    }

    mixin sourceIndexFields;

    float getValue() {
        return source.to!float();
    }

    override string toString() {
        return "%s(%s)".format(kind, source);
    }

    unittest {
        auto a = new LiteralFloat("62.33352", 0);
        assert(a.getValue() == 62.33352f);
        auto b = new LiteralFloat("1.1", 0);
        assert(b.getValue() == 1.1f);
        auto c = new LiteralFloat("0.1", 0);
        assert(c.getValue() == 0.1f);
    }
}

class Eof : Token {
    this(size_t index) {
        _start = index;
        _end = index;
    }

    override string getSource() {
        return "\u0004";
    }

    @property TokenKind kind() {
        return TokenKind.EOF;
    }

    mixin sourceIndexFields;

    override string toString() {
        return "EOF()";
    }
}

alias FixedTokenCtor = Token function(size_t);

private enum FixedTokenCtor[string] KEYWORD_CTOR_MAP = buildFixedTokenCtorMap!(
    KeywordVar, KeywordIf, KeywordElse, KeywordWhile, KeywordDo
);

private enum FixedTokenCtor[string] OPERATOR_CTOR_MAP = buildFixedTokenCtorMap!(
    OperatorPlus, OperatorMinus, OperatorTimes, OperatorDivide, OperatorAssign,
    OperatorOpenParenthesis, OperatorCloseParenthesis
);

// Template magic to convert the token type list to a map from the token character to the class constructor
private FixedTokenCtor[string] buildFixedTokenCtorMap(Token, Tokens...)() {
    static if (is(Token == FixedToken!(kind, source), TokenKind kind, string source)) {
        static if (Tokens.length > 0) {
            auto map = buildFixedTokenCtorMap!Tokens();
        } else {
            FixedTokenCtor[string] map;
        }
        map[source] = (size_t start) => new Token(start);
        return map;
    } else {
        static assert (0);
    }
}

bool isKeyword(string identifier) {
    return (identifier in KEYWORD_CTOR_MAP) !is null;
}

Token createKeyword(string source, size_t start) {
    return KEYWORD_CTOR_MAP[source](start);
}

bool isOperator(char c) {
    return (c.to!string() in OPERATOR_CTOR_MAP) !is null;
}

Token createOperator(char source, size_t start) {
    return OPERATOR_CTOR_MAP[source.to!string()](start);
}
