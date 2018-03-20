module pardus.identical;

import openmethods: registerMethods, virtual, method;

import pardus.type;
import pardus.cycle;

mixin(registerMethods);

private alias TypesCycles = Cycles!(LinkType, 2);

bool identical(Type left, Type right) {
    return left is right || left.identical(right, new TypesCycles());
}

bool identical(virtual!Type right, virtual!Type left, TypesCycles cycles);

@method
bool _identical(Type left, Type right, TypesCycles cycles) {
    return left is right;
}

@method
bool _identical(BoolType left, BoolType right, TypesCycles cycles) {
    return left.modifiers == right.modifiers;
}

@method
bool _identical(IntType left, IntType right, TypesCycles cycles) {
    return left.modifiers == right.modifiers && left.bytes == right.bytes && left.signed == right.signed;
}

@method
bool _identical(FloatType left, FloatType right, TypesCycles cycles) {
    return left.modifiers == right.modifiers && left.bytes == right.bytes;
}

@method
bool _identical(TupleType left, TupleType right, TypesCycles cycles) {
    if (left.modifiers != right.modifiers || left.size() != right.size()) {
        return false;
    }
    foreach (i; 0 .. left.size()) {
        if (!left[i].identical(right[i], cycles)) {
            return false;
        }
    }
    return true;
}

@method
bool _identical(StructType left, StructType right, TypesCycles cycles) {
    if (left.modifiers != right.modifiers || left.size() != right.size()) {
        return false;
    }
    foreach (i, fieldName; left.fieldNames) {
        if (fieldName !in right || !left[i].identical(right[fieldName], cycles)) {
            return false;
        }
    }
    return true;
}

@method
bool _identical(ArrayType left, ArrayType right, TypesCycles cycles) {
    return left.modifiers == right.modifiers && left.size == right.size && (*left).identical(*right, cycles);
}

@method
bool _identical(SliceType left, SliceType right, TypesCycles cycles) {
    return left.modifiers == right.modifiers && (*left).identical(*right, cycles);
}

@method
bool _identical(PointerType left, PointerType right, TypesCycles cycles) {
    return left.modifiers == right.modifiers && (*left).identical(*right, cycles);
}

@method
bool _identical(FunctionType left, FunctionType right, TypesCycles cycles) {
    if (left.modifiers != right.modifiers || left.size() != right.size() || !left.ret.identical(right.ret, cycles)) {
        return false;
    }
    foreach (i; 0 .. left.size()) {
        if (!left[i].identical(right[i], cycles) || left.paramNames[i] != right.paramNames[i]) {
            return false;
        }
    }
    return true;
}

@method
bool _identical(LinkType left, LinkType right, TypesCycles cycles) {
    if (cycles.traverse(left, right)) {
        return true;
    }
    return left.link.identical(right.link, cycles);
}

@method
bool _identical(LinkType left, Type right, TypesCycles cycles) {
    return left.link.identical(right, cycles);
}

@method
bool _identical(Type left, LinkType right, TypesCycles cycles) {
    return left.identical(right.link, cycles);
}

@method
bool _identical(LitBoolType left, LitBoolType right, TypesCycles cycles) {
    return left.value == right.value;
}

@method
bool _identical(LitUIntType left, LitUIntType right, TypesCycles cycles) {
    return left.value == right.value;
}

@method
bool _identical(LitSIntType left, LitSIntType right, TypesCycles cycles) {
    return left.value == right.value;
}

@method
bool _identical(LitFloatType left, LitFloatType right, TypesCycles cycles) {
    return left.value == right.value;
}

@method
bool _identical(LitTupleType left, LitTupleType right, TypesCycles cycles) {
    if (left.size() != right.size()) {
        return false;
    }
    foreach (i; 0 .. left.size()) {
        if (!left[i].identical(right[i], cycles)) {
            return false;
        }
    }
    return true;
}

@method
bool _identical(LitStructType left, LitStructType right, TypesCycles cycles) {
    if (left.size() != right.size()) {
        return false;
    }
    foreach (i, fieldName; left.fieldNames) {
        if (fieldName !in right || !left[i].identical(right[fieldName], cycles)) {
            return false;
        }
    }
    return true;
}

@method
bool _identical(LitPointerType left, LitPointerType right, TypesCycles cycles) {
    return (*left).identical(*right, cycles);
}

@method
bool _identical(LitSizeSliceType left, LitSizeSliceType right, TypesCycles cycles) {
    return left.modifiers == right.modifiers && left.size == right.size && (*left).identical(*right, cycles);
}
