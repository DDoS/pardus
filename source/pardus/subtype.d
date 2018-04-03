module pardus.subtype;

import openmethods: registerMethods, virtual, method;

import pardus.type;
import pardus.identical;
import pardus.mutable;

mixin(registerMethods);

bool subtype(virtual!Type right, virtual!Type left);

private bool subtype(Mutability left, Mutability right) {
    return left == right || right == Mutability.UNKNOWN;
}

private bool subtype(Modifiers left, Modifiers right) {
    return left.mutability.subtype(right.mutability) && left.identified && right.identified;
}

@method
bool _subtype(Type left, Type right) {
    return left.identical(right);
}

@method
bool _subtype(DefinedType left, DefinedType right) {
    if (!left.modifiers.mutability.subtype(right.modifiers.mutability)
            || left.modifiers.identified != right.modifiers.identified) {
        return false;
    }
    return left.makeValueMutable().identical(right.makeValueMutable());
}

@method
bool _subtype(TupleType left, TupleType right) {
    if (!left.modifiers.subtype(right.modifiers) || left.size() < right.size()) {
        return false;
    }
    foreach (i, field; right.fields) {
        if (!left[i].identical(field)) {
            return false;
        }
    }
    return true;
}

@method
bool _subtype(StructType left, StructType right) {
    if (!left.modifiers.subtype(right.modifiers) || left.size() < right.size()) {
        return false;
    }
    foreach (i, fieldName; left.fieldNames) {
        if (fieldName !in right || !left[i].identical(right[fieldName])) {
            return false;
        }
    }
    return true;
}

@method
bool _subtype(TupleType left, StructType right) {
    return false;
}
