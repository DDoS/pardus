module pardus.print;

import std.format : format;

import openmethods: registerMethods, virtual, method;

import pardus.type;
import pardus.util;

mixin(registerMethods);

string print(virtual!Type type);

@method
string _print(Type type) {
    return type.printRaw();
}

@method
string _print(DefinedType type) {
    auto raw = type.printRaw();
    string modifier = void;
    final switch (type.modifiers.mutability) with (Mutability) {
        case MUTABLE: {
            modifier = "";
        }
        break;
        case IMMUTABLE: {
            modifier = "!";
        }
        break;
        case UNKNOWN: {
            modifier = "?";
        }
        break;
    }
    return raw ~ modifier;
}

string printRaw(virtual!Type type);

@method
string _printRaw(BoolType type) {
    return "bool";
}

@method
string _printRaw(IntType type) {
    return type.name;
}

@method
string _printRaw(FloatType type) {
    return type.name;
}

@method
string _printRaw(TupleType type) {
    return "{%s}".format(type.fields.join!(", ", print));
}

@method
string _printRaw(StructType type) {
    return "{%s}".format(stringZip!(" ", print, a => a)(type.fields, type.fieldNames).join!", "());
}

@method
string _printRaw(ArrayType type) {
    return type.component.print() ~ "[%d]".format(type.size);
}

@method
string _printRaw(SliceType type) {
    return type.component.print() ~ "[*]";
}

@method
string _printRaw(PointerType type) {
    return type.value.print() ~ "*";
}

@method
string _printRaw(FunctionType type) {
    return "func (%s)%s".format(
        stringZip!("", print, a => a.length == 0 ? "" : ' ' ~ a)(type.params, type.paramNames).join!", "(),
        type.ret is null ? "" : ' ' ~ type.ret.print()
    );
}

@method
string _printRaw(BackRefType type) {
    return type.name;
}

@method
string _printRaw(LitBoolType type) {
    return type.value ? "true" : "false";
}

@method
string _printRaw(LitUIntType type) {
    return "%du".format(type.value);
}

@method
string _printRaw(LitSIntType type) {
    return "%d".format(type.value);
}

@method
string _printRaw(LitFloatType type) {
    return "%g".format(type.value);
}

@method
string _printRaw(LitTupleType type) {
    return "{%s}".format(type.fields.join!(", ", print));
}

@method
string _printRaw(LitStructType type) {
    return "{%s}".format(stringZip!(" ", print, a => a)(type.fields, type.fieldNames).join!", "());
}

@method
string _printRaw(LitPointerType type) {
    return type.value.print() ~ "*";
}

@method
string _printRaw(LitSizeSliceType type) {
    return "%s[*%d]".format(type.component.print(), type.size.value);
}
