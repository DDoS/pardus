module pardus.util;

import std.range.primitives : isInputRange, ElementType;
import std.algorithm.iteration : map, reduce;
import std.range : zip;

auto stringZip(string joiner, alias stringerA, alias stringerB, RangeA, RangeB)
        (RangeA a, RangeB b) if (isInputRange!RangeA && isInputRange!RangeB) {
    return zip(a, b).map!(ab => (stringerA(ab[0]) ~ joiner ~ stringerB(ab[1])));
}

string join(string joiner, alias stringer, Range)(Range things)
        if (isInputRange!Range) {
    if (things.length <= 0) {
        return "";
    }
    return things.map!stringer().reduce!((a, b) => a ~ joiner ~ b);
}

string join(string joiner, Range)(Range things)
        if (isInputRange!Range && is(ElementType!Range == string)) {
    if (things.length <= 0) {
        return "";
    }
    return things.reduce!((a, b) => a ~ joiner ~ b);
}

T tryCast(T, S)(S s) {
    T t = cast(T) s;
    if (t) {
        return t;
    }
    throw new Exception("Cannot cast " ~ __traits(identifier, S) ~ " to " ~ __traits(identifier, T));
}
