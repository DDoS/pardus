module pardus.syntax.chars;

import std.format : format;
import std.conv : to;

import pardus.util;

private enum char[char] CHAR_TO_ESCAPE = [
    't': '\t',
    'n': '\n',
    'r': '\r',
    '"': '"',
    '\\': '\\'
];
private enum char[char] ESCAPE_TO_CHAR = CHAR_TO_ESCAPE.inverse();

bool isIdentifierStart(char c) {
    return c == '_' || c.isLetter();
}

bool isIdentifierBody(char c) {
    return c.isIdentifierStart() || c.isDecimalDigit();
}

bool isLetter(char c) {
    return c >= 'A' && c <= 'Z' || c >= 'a' && c <= 'z';
}

bool isDecimalDigit(char c) {
    return c >= '0' && c <= '9';
}

bool isHexadecimalDigit(char c) {
    return c.isDecimalDigit() || c >= 'A' && c <= 'F' || c >= 'a' && c <= 'f';
}

bool isNewLine(char c) {
    return c == '\n' || c == '\r';
}

bool isLineWhiteSpace(char c) {
    return c == ' ' || c == '\t';
}

bool isWhiteSpace(char c) {
    return c.isNewLine() || c.isLineWhiteSpace();
}

bool isPrintable(char c) {
    return c >= ' ' && c <= '~';
}

bool isEscapeChar(char c) {
    return (c in CHAR_TO_ESCAPE) !is null;
}

char decodeCharEscape(char c) {
    auto optChar = c in CHAR_TO_ESCAPE;
    if (optChar is null) {
        throw new Error(format("Not a valid escape character: %s", c.escapeChar()));
    }
    return *optChar;
}

string escapeChar(char c) {
    auto optEscape = c in ESCAPE_TO_CHAR;
    if (optEscape !is null) {
        return "\\" ~ (*optEscape).to!string();
    }
    if (c.isPrintable()) {
        return c.to!string();
    }
    if (c == '\u0004') {
        return "EOF";
    }
    return "0x%02X".format(c);
}
