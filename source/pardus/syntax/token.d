module pardus.syntax.token;

import std.format : format;
import std.conv : to, ConvOverflowException;
import std.exception : assumeUnique;

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

    SYMBOL_PLUS,
    SYMBOL_MINUS,
    SYMBOL_TIMES,
    SYMBOL_POWER,
    SYMBOL_DIVIDE,
    SYMBOL_ASSIGN,
    SYMBOL_OPEN_PARENTHESIS,
    SYMBOL_CLOSE_PARENTHESIS,

    LITERAL_SINT,
    LITERAL_UINT,
    LITERAL_FLOAT,
    LITERAL_STRING,
    LITERAL_CHARACTER,

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
    class FixedToken : Token {
        this(size_t start) {
            _start = start;
            _end = start + source.length;
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

alias SymbolPlus = FixedToken!(TokenKind.SYMBOL_PLUS, "+");
alias SymbolMinus = FixedToken!(TokenKind.SYMBOL_MINUS, "-");
alias SymbolTimes = FixedToken!(TokenKind.SYMBOL_TIMES, "*");
alias SymbolPower = FixedToken!(TokenKind.SYMBOL_POWER, "**");
alias SymbolDivide = FixedToken!(TokenKind.SYMBOL_DIVIDE, "/");
alias SymbolAssign = FixedToken!(TokenKind.SYMBOL_ASSIGN, "=");
alias SymbolOpenParenthesis = FixedToken!(TokenKind.SYMBOL_OPEN_PARENTHESIS, "(");
alias SymbolCloseParenthesis = FixedToken!(TokenKind.SYMBOL_CLOSE_PARENTHESIS, ")");

class Identifier : Token {
    private string source;

    this(string source, size_t start) {
        this.source = source;
        _start = start;
        _end = start + source.length;
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

class StringLiteral : Token {
    private string source;

    this(string source, size_t start) {
        this.source = source;
        _start = start;
        _end = start + source.length;
    }

    override string getSource() {
        return source;
    }

    @property override TokenKind kind() {
        return TokenKind.LITERAL_STRING;
    }

    mixin sourceIndexFields;

    string getValue() {
        return source.decodeString('"');
    }

    override string toString() {
        return "%s(%s)".format(kind, source);
    }

    unittest {
        auto a = new StringLiteral("\"hel\\\"lo\"", 0);
        assert(a.getValue() == "hel\"lo");
        auto b = new StringLiteral("\"hel\\\\lo\"", 0);
        assert(b.getValue() == "hel\\lo");
        auto c = new StringLiteral("\"hel\\nlo\"", 0);
        assert(c.getValue() == "hel\nlo");
        auto d = new StringLiteral("\"hel\\r\\n\\vlo\"", 0);
        assert(d.getValue() == "hel\r\t\nlo");
    }
}

class CharacterLiteral : Token {
    private string source;

    this(string source, size_t start) {
        this.source = source;
        _start = start;
        _end = start + source.length;
    }

    override string getSource() {
        return source;
    }

    @property override TokenKind kind() {
        return TokenKind.LITERAL_CHARACTER;
    }

    mixin sourceIndexFields;

    char getValue() {
        auto value = source.decodeString('\'');
        if (value.length > 1) {
            throw new Error("Character literal encoded more than one character");
        }
        return value[0];
    }

    override string toString() {
        return "%s(%s)".format(kind, source);
    }
}

private string decodeString(string data, char quote) {
    auto length = data.length;
    if (length < 2) {
        throw new Error("String is missing enclosing quotes");
    }
    if (data[0] != quote) {
        throw new Error("String is missing beginning quote");
    }
    auto value = data[1 .. length - 1].decodeStringContent();
    if (data[length - 1] != quote) {
        throw new Error("String is missing ending quote");
    }
    return value;
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

private template IntegerLiteral(bool signed) {
    static if (signed) {
        private alias integer = long;
    } else {
        private alias integer = ulong;
    }

    class IntegerLiteral : Token {
        private uint base;
        private string source;

        this(uint base, string source, size_t start) {
            this.base = base;
            this.source = source;
            _start = start;
            _end = start + source.length;
        }

        override string getSource() {
            return source;
        }

        @property override TokenKind kind() {
            static if (signed) {
                return TokenKind.LITERAL_SINT;
            } else {
                return TokenKind.LITERAL_UINT;
            }
        }

        mixin sourceIndexFields;

        integer getValue(out bool overflow) {
            string noPrefix = base != 10 ? source[2 .. $] : source;
            try {
                overflow = false;
                return noPrefix.to!integer(base);
            } catch (ConvOverflowException) {
                overflow = true;
                return -1;
            }
        }

        override string toString() {
            return "%s(%s)".format(kind, source);
        }
    }
}

alias SIntLiteral = IntegerLiteral!true;
alias UIntLiteral = IntegerLiteral!false;

unittest {
    bool overflow;
    auto a = new IntLiteral("42432", 0);
    assert(a.getValue(overflow) == 42432);
    assert(!overflow);
    auto b = new IntLiteral("9223372036854775808", 0);
    b.getValue(overflow);
    assert(overflow);
}

class FloatLiteral : Token {
    private string source;

    this(string source, size_t start) {
        this.source = source;
        _start = start;
        _end = start + source.length;
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
        auto a = new FloatLiteral("62.33352", 0);
        assert(a.getValue() == 62.33352f);
        auto b = new FloatLiteral("1.1", 0);
        assert(b.getValue() == 1.1f);
        auto c = new FloatLiteral("0.1", 0);
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

private immutable FixedTokenCtor[string] KEYWORD_CTOR_MAP;
private immutable FixedTokenCtor[string] SYMBOL_CTOR_MAP;
private immutable bool[string] SYMBOL_PREFIXES;

shared static this() {
    auto keywordMap = buildFixedTokenCtorMap!(
        KeywordVar, KeywordIf, KeywordElse, KeywordWhile, KeywordDo
    );
    keywordMap.rehash();
    KEYWORD_CTOR_MAP = keywordMap.assumeUnique();

    auto symbolMap = buildFixedTokenCtorMap!(
        SymbolPlus, SymbolMinus, SymbolTimes, SymbolPower, SymbolDivide, SymbolAssign,
        SymbolOpenParenthesis, SymbolCloseParenthesis
    );
    symbolMap.rehash();
    SYMBOL_CTOR_MAP = symbolMap.assumeUnique();

    bool[string] symbolPrefixes;
    size_t prefixLength = 0;
    bool addedPrefix = void;
    do {
        prefixLength += 1;
        addedPrefix = false;
        foreach (op; SYMBOL_CTOR_MAP.byKey()) {
            if (prefixLength <= op.length) {
                symbolPrefixes[op[0 .. prefixLength]] = true;
                addedPrefix = true;
            }
        }
    } while (addedPrefix);
    symbolPrefixes.rehash();
    SYMBOL_PREFIXES = symbolPrefixes.assumeUnique();
}

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

bool isSymbolPrefix(char prefix) {
    return isSymbolPrefix(prefix.to!string());
}

bool isSymbolPrefix(string prefix) {
    return (prefix in SYMBOL_PREFIXES) !is null;
}

Token createSymbol(string source, size_t start) {
    return SYMBOL_CTOR_MAP[source](start);
}
