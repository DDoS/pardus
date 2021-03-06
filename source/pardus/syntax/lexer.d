module pardus.syntax.lexer;

import std.format : format;

import pardus.syntax.chars;
import pardus.syntax.source;
import pardus.syntax.token;

class Lexer {
    private SourceReader reader;
    private Token[] headTokens;
    private size_t position = 0;
    private size_t[] savedPositions;

    this(SourceReader reader) {
        this.reader = reader;
        headTokens.reserve(32);
        savedPositions.reserve(32);
    }

    bool has() {
        return head().kind != TokenKind.EOF;
    }

    Token head() {
        while (headTokens.length <= position) {
            headTokens ~= next();
        }
        return headTokens[position];
    }

    void advance() {
        if (head().kind != TokenKind.EOF) {
            position++;
        }
    }

    void savePosition() {
        savedPositions ~= position;
    }

    void restorePosition() {
        position = savedPositions[$ - 1];
        discardPosition();
    }

    void discardPosition() {
        savedPositions.length--;
    }

    private Token next() {
        while (reader.has()) {
            if (reader.head().isWhiteSpace()) {
                // Ignore whitespace
                reader.advance();
                continue;
            }
            if (reader.head() == '#') {
                // Line or block comment
                reader.advance();
                if (reader.head() == '#') {
                    reader.advance();
                    reader.consumeBlockComment();
                } else {
                    reader.consumeLineCommentText();
                }
                continue;
            }
            if (reader.head() == ':') {
                // Colon
                reader.advance();
                return new Colon(reader.count - 1);
            }
            if (reader.head() == ';') {
                // Semicolon
                reader.advance();
                return new Semicolon(reader.count - 1);
            }
            if (reader.head().isIdentifierStart()) {
                // Identifier or keyword
                auto position = reader.count;
                reader.collect();
                auto identifier = reader.collectIdentifierBody();
                if (identifier.isKeyword()) {
                    return identifier.createKeyword(position);
                }
                return new Identifier(identifier, position);
            }
            if (reader.head().isSymbolPrefix()) {
                // Symbol
                auto position = reader.count;
                return createSymbol(reader.collectSymbol(), position);
            }
            if (reader.head() == '"') {
                // String literal
                auto position = reader.count;
                return new StringLiteral(reader.collectStringLiteral(), position);
            }
            if (reader.head() == '\'') {
                // Character literal
                auto position = reader.count;
                return new CharacterLiteral(reader.collectCharacterLiteral(), position);
            }
            if (reader.head().isDecimalDigit()) {
                // Int or float literal
                return reader.collectNumberLiteral();
            }
            // Unknown
            throw new SourceException("Unexpected character", reader.head(), reader.count);
        }
        // End of file
        return new Eof(reader.count);
    }
}

private string collectIdentifierBody(SourceReader reader) {
    while (reader.head().isIdentifierBody()) {
        reader.collect();
    }
    return reader.popCollected();
}

private void consumeLineCommentText(SourceReader reader) {
    while (reader.has() && !reader.head().isNewLine()) {
        reader.advance();
    }
    if (reader.has()) {
        reader.consumeNewLine();
    }
}

private void consumeBlockComment(SourceReader reader) {
    // Count and consume leading # symbols
    // Count starts at 2 because otherwise it's a line comment
    auto leading = 2;
    while (reader.head() == '#') {
        leading += 1;
        reader.advance();
    }
    // Consume anything until matching sequence of # is found
    auto trailing = 0;
    while (reader.has() && trailing < leading) {
        if (reader.head() == '#') {
            trailing += 1;
        } else {
            trailing = 0;
        }
        reader.advance();
    }
}

private void consumeNewLine(SourceReader reader) {
    if (reader.head() == '\r') {
        // CR
        reader.advance();
        if (reader.head() == '\n') {
            // CR LF
            reader.advance();
        }
    } else if (reader.head() == '\n') {
        // LF
        reader.advance();
    }
}

private string collectSymbol(SourceReader reader) {
    while (reader.peekCollected().isSymbolPrefix()) {
        reader.collect();
    }
    return reader.popCollected();
}

private string collectStringLiteral(SourceReader reader) {
    // Opening "
    if (reader.head() != '"') {
        throw new SourceException("Expected opening \"", reader.head(), reader.count);
    }
    reader.collect();
    // String contents
    while (true) {
        if ((reader.head().isPrintable() || reader.head().isLineWhiteSpace())
                && reader.head() != '"' && reader.head() != '\\') {
            // Collect a normal character with no special meaning in a string
            reader.collect();
        } else if (reader.collectEscapeSequence()) {
            // Nothing to do, it is already collected in the "if" call
        } else {
            // Not part of a string literal body, end here
            break;
        }
    }
    // Closing "
    if (reader.head() != '"') {
        throw new SourceException("Expected closing \"", reader.head(), reader.count);
    }
    reader.collect();
    return reader.popCollected();
}

private string collectCharacterLiteral(SourceReader reader) {
    // Opening '
    if (reader.head() != '\'') {
        throw new SourceException("Expected opening \'", reader.head(), reader.count);
    }
    reader.collect();
    // Character contents
    if (reader.head().isPrintable() && reader.head() != '\\') {
        reader.collect();
    } else if (reader.collectEscapeSequence()) {
        // Nothing to do, it is already collected in the "if" call
    } else {
        throw new SourceException("Unsupported character literal", reader.head(), reader.count);
    }
    // Closing '
    if (reader.head() != '\'') {
        throw new SourceException("Expected closing \'", reader.head(), reader.count);
    }
    reader.collect();
    return reader.popCollected();
}

private bool collectEscapeSequence(SourceReader reader) {
    if (reader.head() != '\\') {
        return false;
    }
    reader.collect();
    // Check for unicode sequence
    if (reader.head() == 'u') {
        reader.collect();
        reader.collectHexadecimalSequence(4);
        return true;
    }
    // Check for wide unicode sequence
    if (reader.head() == 'w') {
        reader.collect();
        reader.collectHexadecimalSequence(8);
        return true;
    }
    // Check for other common escapes
    if (reader.head().isEscapeChar()) {
        reader.collect();
        return true;
    }
    throw new SourceException("Not a valid escape sequence", reader.head(), reader.count);
}

private Token collectNumberLiteral(SourceReader reader) {
    auto position = reader.count;
    uint base = 10;
    if (reader.head() == '0') {
        // Collect according to base identifier
        switch (reader.head(1)) {
            case 'b':
            case 'B': {
                reader.collect();
                reader.collect();
                base = 2;
                reader.collectSplitBinarySequence();
            }
            break;
            case 'c':
            case 'C': {
                reader.collect();
                reader.collect();
                base = 8;
                reader.collectSplitOctalSequence();
            }
            break;
            case 'x':
            case 'X': {
                reader.collect();
                reader.collect();
                base = 16;
                reader.collectSplitHexadecimalSequence();
            }
            break;
            default: {
                reader.collectSplitDecimalSequence();
            }
        }
    }
    // In base 10 check for a float literal
    if (base == 10) {
        bool isFloat = false;
        // Check for a decimal separator and more digits
        if (reader.head() == '.') {
            isFloat = true;
            reader.collectSplitDecimalSequence();
        }
        // Check for an exponent separator
        if (reader.head() == 'e' || reader.head() == 'E') {
            isFloat = true;
            // Optional sign with mandatory digits
            reader.collect();
            if (reader.head() == '+' || reader.head() == '-') {
                reader.collect();
            }
            reader.collectDecimalSequence();
        }
        if (isFloat) {
            return new FloatLiteral(reader.popCollected(), position);
        }
    }
    // Else it's just a integer, check for the unsigned suffix
    if (reader.head() == 'u' || reader.head() == 'U') {
        return new UIntLiteral(base, reader.popCollected(), position);
    }
    return new SIntLiteral(base, reader.popCollected(), position);
}

alias collectDecimalSequence = collectSequence!(isDecimalDigit, "decimal digit");
alias collectHexadecimalSequence = collectSequence!(isHexadecimalDigit, "hexadecimal digit");

alias collectSplitBinarySequence = collectSplitSequence!(isBinaryDigit, '_', "binary digit");
alias collectSplitOctalSequence = collectSplitSequence!(isOctalDigit, '_', "octal digit");
alias collectSplitDecimalSequence = collectSplitSequence!(isDecimalDigit, '_', "decimal digit");
alias collectSplitHexadecimalSequence = collectSplitSequence!(isHexadecimalDigit, '_', "hexadecimal digit");

private void collectSplitSequence(alias predicate, char splitter, string name)(SourceReader reader) {
    reader.collectSequence!(predicate, name);
    while (reader.head() == splitter) {
        reader.collect();
        reader.collectSequence!(predicate, name);
    }
}

alias collectIdentifierBody = collectSequence!(isIdentifierBody, "identifier character");

private void collectSequence(alias predicate, string name)(SourceReader reader, size_t count = 0) {
    if (!predicate(reader.head())) {
        throw new SourceException("Expected a " ~ name, reader.head(), reader.count);
    }
    reader.collect();
    size_t n = 1;
    while (predicate(reader.head()) && (count == 0 || n < count)) {
        reader.collect();
        n += 1;
    }
    if (count != 0 && n < count) {
        throw new SourceException("Expected %s more %s(s)".format(count - n, name), reader.head(), reader.count);
    }
}
