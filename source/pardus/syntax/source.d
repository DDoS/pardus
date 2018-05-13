module pardus.syntax.source;

import std.conv : to;
import std.string : stripRight;
import std.format : format;
import std.algorithm.comparison : min;
import std.exception : assumeUnique;
import std.ascii : newline;

import pardus.syntax.chars;

string escapeString(string source) {
    char[] buffer;
    buffer.reserve(source.length);
    foreach (c; source) {
        buffer ~= c.escapeChar();
    }
    return buffer.assumeUnique();
}

class SourceReader {
    private enum size_t DEFAULT_COLLECT_SIZE = 16;
    private string source;
    private size_t index = 0;
    private char[] collected;
    private size_t collectedCount = 0;

    this(string source) {
        this.source = source;
        collected.length = DEFAULT_COLLECT_SIZE;
    }

    bool has(size_t offset = 0) {
        return index + offset < source.length;
    }

    char head(size_t offset = 0) {
        if (!has(offset)) {
            return '\u0004';
        }
        return source[index + offset];
    }

    @property size_t count() {
        return index;
    }

    void advance() {
        index++;
    }

    void collect() {
        collected[collectedCount++] = head();
        if (collectedCount >= collected.length) {
            collected.length += DEFAULT_COLLECT_SIZE;
        }
        advance();
    }

    string peekCollected() {
        return collected[0 .. collectedCount].idup;
    }

    string popCollected() {
        auto cs = peekCollected();
        collected.length = DEFAULT_COLLECT_SIZE;
        collectedCount = 0;
        return cs;
    }
}

unittest {
    auto reader = new SourceReader("this is a test to see hoho l");
    while (reader.head() != ' ') {
        reader.advance();
    }
    while (reader.head() != 'h') {
        reader.collect();
    }
    assert(reader.popCollected() == " is a test to see ");
    while (reader.has()) {
        reader.collect();
    }
    assert(reader.popCollected() == "hoho l");
}

class SourcePrinter {
    private static enum INDENTATION = "    ";
    private char[] buffer;
    private char[] indentation;
    private bool indentNext = false;

    this() {
        buffer.reserve(512);
        indentation.length = 0;
    }

    SourcePrinter print(string str) {
        if (indentNext) {
            buffer ~= indentation;
            indentNext = false;
        }
        buffer ~= str;
        return this;
    }

    SourcePrinter indent() {
        indentation ~= INDENTATION;
        return this;
    }

    SourcePrinter dedent() {
        indentation.length -= INDENTATION.length;
        return this;
    }

    SourcePrinter newLine() {
        buffer ~= newline;
        indentNext = true;
        return this;
    }

    override string toString() {
        return buffer.idup;
    }
}

mixin template sourceIndexFields() {
    private size_t _start;
    private size_t _end;

    @property size_t start() {
        return _start;
    }

    @property size_t end() {
        return _end;
    }

    @property void start(size_t start) {
        _start = start;
    }

    @property void end(size_t end) {
        _end = end;
    }
}

class SourceException : Exception {
    // This is a duck typing trick: "is(type)" only returns true if the type is valid.
    // The type can be that of a lambda, so we declare one and get the type using typeof(lambda).
    // Since typeof doesn't actually evaluate the expression, all that matters is that it compiles.
    // This is where duck typing comes in, the lambda body defines the operations we want on S
    // and only compiles if the operations are valid
    private enum bool isSourceIndexed(S) = is(typeof(
        (inout int = 0) {
            S s = S.init;
            size_t start = s.start;
            size_t end = s.end;
        }
    ));

    private string offender = null;
    private size_t _start;
    private size_t _end;

    this(string message, size_t index) {
        this(message, null, index);
    }

    this(string message, char offender, size_t index) {
        this(message, offender.escapeChar(), index);
    }

    this(string message, string offender, size_t index) {
        super(message);
        this.offender = offender;
        _start = index;
        _end = index;
    }

    this(SourceIndexed)(string message, SourceIndexed problem) if (isSourceIndexed!SourceIndexed) {
        this(message, problem.start, problem.end);
    }

    this(SourceIndexed)(string message, string offender, SourceIndexed problem) if (isSourceIndexed!SourceIndexed) {
        this(message, offender, problem.start, problem.end);
    }

    this(string message, size_t start, size_t end) {
        this(message, null, start, end);
    }

    this(string message, string offender, size_t start, size_t end) {
        super(message);
        assert(start <= end);
        _start = start;
        _end = end;
    }

    @property size_t start() {
        return _start;
    }

    @property size_t end() {
        return _start;
    }

    immutable(ErrorInformation)* getErrorInformation(string source) {
        if (_start > source.length || _end > source.length) {
            throw new Error("_start and/or _end indices are bigger than the source length");
        }
        if (source.length == 0) {
            return new immutable ErrorInformation(this.msg, offender, "", 0, 0, 0, 0);
        }
        // Special case, both start and end are max values when the source is unknown
        if (_start == size_t.max && _end == size_t.max) {
            return new immutable ErrorInformation(this.msg, offender);
        }
        string section = source[_start .. _end];
        // find the line(s) the error occurred on
        size_t startLine = findLineNumber(source, _start);
        size_t endLine = _end != _start ? findLineNumber(source, _end - 1) : startLine;
        // find start and end relative to the line(s)
        size_t lineStart = findPreviousLineEnding(source, _start);
        size_t lineEnd = _end != _start ? findPreviousLineEnding(source, _end - 1) : lineStart;
        return new immutable ErrorInformation(this.msg, offender, section, startLine, endLine, lineStart, lineEnd);
    }

    private static size_t findLineNumber(string source, size_t index) {
        index = min(index, source.length);
        size_t line = 0;
        for (size_t i = 0; i < index; i++) {
            if (source[i].isNewLine()) {
                consumeNewLine(source, i);
                if (i < index) {
                    line++;
                }
            }
        }
        return line;
    }

    private static size_t findPreviousLineEnding(string source, size_t index) {
        if (index >= source.length) {
            return source.length;
        }
        while (index > 0 && !source[index - 1].isNewLine()) {
            index--;
        }
        return index;
    }

    private static void consumeNewLine(string source, ref size_t i) {
        if (source[i] == '\n') {
            // LF
            i++;
        } else if (source[i] == '\r') {
            // CR
            i++;
            if (i < source.length && source[i] == '\n') {
                // CR LF
                i++;
            }
        }
    }

    immutable struct ErrorInformation {
        string message;
        string offender;
        bool knownSource;
        string section;
        size_t startLine;
        size_t endLine;
        size_t lineStart;
        size_t lineEnd;

        this(string message, string offender) {
            this.message = message;
            this.offender = offender;
            knownSource = false;
        }

        this(string message, string offender, string section, size_t startLine, size_t endLine,
                size_t lineStart, size_t lineEnd) {
            this.message = message;
            this.offender = offender;
            knownSource = true;
            this.section = section;
            this.startLine = startLine;
            this.endLine = endLine;
            this.lineStart = lineStart;
            this.lineEnd = lineEnd;
        }

        string toString() {
            // Create a mutable string
            char[] buffer = [];
            buffer.reserve(256);
            // Begin with the error message
            buffer ~= "Error: \"" ~ message ~ '"';
            // Add the offender if known
            if (offender != null) {
                buffer ~= " caused by '" ~ offender ~ '\'';
            }
            // If the source is unknown mention it and stop here
            if (!knownSource) {
                buffer ~= " of unknown source";
                return buffer.idup;
            }
            // Othwerise add the line number and index in that line
            if (lineEnd - lineStart > 1) {
                buffer ~= " from %s:%s to %s:%s".format(startLine, lineStart, endLine, lineEnd);
            } else {
                buffer ~= " at %s:%s".format(startLine, lineStart);
            }
            // Now append the actual line source
            buffer ~= " in \n" ~ section ~ '\n';
            // We'll underline the problem area, so first pad to the start index
            foreach (i; 0 .. lineStart) {
                char pad = void;
                if (i < section.length) {
                    // Use a tab if the source does, to ensure correct alignment
                    pad = section[i] == '\t' ? '\t' : ' ';
                } else {
                    pad = ' ';
                }
                buffer ~= pad;
            }
            // Undeline using a circumflex for a single character, or tildes for many
            if (lineEnd - lineStart <= 1) {
                buffer ~= '^';
            } else {
                foreach (i; lineStart .. lineEnd) {
                    buffer ~= '~';
                }
            }
            return buffer.idup;
        }
    }
}
