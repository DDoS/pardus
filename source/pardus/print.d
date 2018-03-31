module pardus.print;

import std.format : format;

import openmethods: registerMethods, virtual, method;

import pardus.type;
import pardus.cycle;
import pardus.util;

mixin(registerMethods);

private alias TypeCycles = Cycles!(CompositeType, 1);

string print(Type type) {
    return type.print(new TypeCycles());
}

string print(virtual!Type type, TypeCycles cycles);

private string printSuffix(Modifiers modifiers) {
    string identified = modifiers.identified ? "^" : "";
    string mutability = void;
    final switch (modifiers.mutability) with (Mutability) {
        case MUTABLE: {
            mutability = "";
        }
        break;
        case IMMUTABLE: {
            mutability = "!";
        }
        break;
        case UNKNOWN: {
            mutability = "?";
        }
        break;
    }
    return identified ~ mutability;
}

@method
string _print(BoolType type, TypeCycles cycles) {
    return "bool" ~ type.modifiers.printSuffix();
}

@method
string _print(IntType type, TypeCycles cycles) {
    return type.name ~ type.modifiers.printSuffix();
}

@method
string _print(FloatType type, TypeCycles cycles) {
    return type.name ~ type.modifiers.printSuffix();
}

private string print(Type[] fields, immutable string[] fieldNames, TypeCycles cycles) {
    assert(fieldNames.length == 0 || fields.length == fieldNames.length);
    string s = "";
    foreach (i, type; fields) {
        s ~= type.print(cycles);
        if (fieldNames.length > 0 && fieldNames[i].length > 0) {
            s ~= " " ~ fieldNames[i];
        }
        if (i < fields.length - 1) {
            s ~= ", ";
        }
    }
    return s;
}

@method
string _print(TupleType type, TypeCycles cycles) {
    cycles.traverse(type);
    return "{%s}%s".format(print(type.fields, [], cycles), type.modifiers.printSuffix());
}

@method
string _print(StructType type, TypeCycles cycles) {
    cycles.traverse(type);
    return "{%s}%s".format(print(type.fields, type.fieldNames, cycles), type.modifiers.printSuffix());
}

@method
string _print(ArrayType type, TypeCycles cycles) {
    cycles.traverse(type);
    return "%s[%d]%s".format(type.component.print(cycles), type.size, type.modifiers.printSuffix());
}

@method
string _print(SliceType type, TypeCycles cycles) {
    cycles.traverse(type);
    return "%s[*]%s".format(type.component.print(cycles), type.modifiers.printSuffix());
}

@method
string _print(PointerType type, TypeCycles cycles) {
    cycles.traverse(type);
    return "%s*%s".format(type.value.print(cycles), type.modifiers.printSuffix());
}

@method
string _print(FunctionType type, TypeCycles cycles) {
    auto ret = type.ret is null ? "" : ' ' ~ type.ret.print(cycles);
    return "func%s (%s)%s".format(type.modifiers.printSuffix(), print(type.params, type.paramNames, cycles), ret);
}

@method
string _print(LinkType type, TypeCycles cycles) {
    if (cycles.traverse(type.link)) {
        return type.name;
    }
    return type.link.print(cycles);
}

@method
string _print(LitBoolType type, TypeCycles cycles) {
    return type.value ? "true" : "false";
}

@method
string _print(LitUIntType type, TypeCycles cycles) {
    return "%du".format(type.value);
}

@method
string _print(LitSIntType type, TypeCycles cycles) {
    return "%d".format(type.value);
}

@method
string _print(LitFloatType type, TypeCycles cycles) {
    return "%g".format(type.value);
}

@method
string _print(LitTupleType type, TypeCycles cycles) {
    return "{%s}".format(type.fields.join!(", ", print));
}

@method
string _print(LitStructType type, TypeCycles cycles) {
    return "{%s}".format(print(type.fields, type.fieldNames, cycles));
}

@method
string _print(LitPointerType type, TypeCycles cycles) {
    return "%s*".format(type.value.print(cycles));
}

@method
string _print(LitSizeSliceType type, TypeCycles cycles) {
    cycles.traverse(type);
    return "%s[*%d]%s".format(type.component.print(cycles), type.size.value, type.modifiers.printSuffix());
}
