module pardus.copiable;

import openmethods: registerMethods, virtual, method;

import pardus.type;
import pardus.identical;
import pardus.mutable;
import pardus.subtype;

mixin(registerMethods);

bool copiableAs(virtual!Type right, virtual!Type left);

@method
bool _copiableAs(Type left, Type right) {
    return left.makeValueMutable().identical(right.makeValueMutable());
}

@method
bool _copiableAs(IntType left, IntType right) {
    if (left.signed == right.signed) {
        return left.bits <= right.bits;
    }
    if (!left.signed && right.signed) {
        return left.bits < right.bits;
    }
    return false;
}

@method
bool _copiableAs(FloatType left, FloatType right) {
    return left.bits <= right.bits;
}

@method
bool _copiableAs(IntType left, FloatType right) {
    final switch (right.bits) {
        case 16:
            return left.bits <= 16;
        case 32:
        case 64:
            return true;
    }
}

@method
bool _copiableAs(TupleType left, StructType right) {
    if (left.size() != right.size()) {
        return false;
    }
    foreach (i, field; left.fields) {
        if (!field.identical(right[i])) {
            return false;
        }
    }
    return true;
}

bool _copiableAs(StructType left, TupleType right) {
    return right.copiableAs(left);
}

@method
bool _copiableAs(TupleType left, ArrayType right) {
    foreach (field; left.fields) {
        if (!field.identical(*right)) {
            return false;
        }
    }
    return true;
}

@method
bool _copiableAs(ArrayType left, TupleType right) {
    return right.copiableAs(left);
}

@method
bool _copiableAs(PointerType left, PointerType right) {
    return (*left).subtype(*right);
}

@method
bool _copiableAs(LitBoolType left, BoolType right) {
    return true;
}

private long minValue(IntType type) {
    return type.signed ? -1L << (type.bits - 1) : 0;
}

private ulong maxValue(IntType type) {
    auto usableBits = type.bits - (type.signed ? 1 : 0);
    return -1UL >>> (64 - usableBits);
}

@method
bool _copiableAs(LitUIntType left, IntType right) {
    return left.value <= right.maxValue();
}

@method
bool _copiableAs(LitSIntType left, IntType right) {
    return left.value >= right.minValue() && (right.signed
        ? left.value <= cast(long) right.maxValue()
        : left.value <= cast(ulong) right.maxValue());
}

private double magnitude(FloatType type) {
    final switch (type.bits) {
        case 16:
            return +0x1.ffcP+15;
        case 32:
            return +0x1.fffffeP+127;
        case 64:
            return +0x1.fffffffffffffP+1023;
    }
}

@method
bool _copiableAs(LitFloatType left, FloatType right) {
    auto magnitude = right.magnitude();
    return left.value >= -magnitude && left.value <= magnitude;
}

@method
bool _copiableAs(LitUIntType left, FloatType right) {
    auto magnitude = right.magnitude();
    return left.value >= -magnitude && left.value <= magnitude;
}

@method
bool _copiableAs(LitSIntType left, FloatType right) {
    auto magnitude = right.magnitude();
    return left.value >= -magnitude && left.value <= magnitude;
}

@method
bool _copiableAs(LitTupleType left, TupleType right) {
    if (left.size() != right.size()) {
        return false;
    }
    foreach (i; 0 .. left.size()) {
        if (!left[i].copiableAs(right[i])) {
            return false;
        }
    }
    return true;
}

@method
bool _copiableAs(LitTupleType left, ArrayType right) {
    if (left.size() != right.size) {
        return false;
    }
    foreach (i; 0 .. left.size()) {
        if (!left[i].copiableAs(*right)) {
            return false;
        }
    }
    return true;
}

@method
bool _copiableAs(LitStructType left, StructType right) {
    if (left.size() != right.size()) {
        return false;
    }
    foreach (i, fieldName; left.fieldNames) {
        if (fieldName !in right || !left[i].copiableAs(right[fieldName])) {
            return false;
        }
    }
    return true;
}

@method
bool _copiableAs(LitStructType left, ArrayType right) {
    return false;
}

@method
bool _copiableAs(LitPointerType left, PointerType right) {
    return (*left).copiableAs(*right);
}

@method
bool _copiableAs(LitPointerType left, SliceType right) {
    if (auto tupleLeft = cast(LitTupleType) *left) {
        foreach (i; 0 .. tupleLeft.size()) {
            if (!tupleLeft[i].copiableAs(*right)) {
                return false;
            }
        }
        return true;
    }
    return false;
}

@method
bool _copiableAs(LitSizeSliceType left, SliceType right) {
    return (*left).identical(*right);
}
