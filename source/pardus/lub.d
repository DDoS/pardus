module pardus.lub;

import std.algorithm.comparison : min;

import openmethods: registerMethods, virtual, method;

import pardus.type;
import pardus.identical;
import pardus.copiable;

mixin(registerMethods);

Type lowestUpperBound(virtual!Type right, virtual!Type left);

@method
Type _lowestUpperBound(Type left, Type right) {
    if (left.copiableAs(right)) {
        return right;
    }
    if (right.copiableAs(left)) {
        return left;
    }
    return null;
}

@method
Type _lowestUpperBound(PointerType left, PointerType right) {
    return (*left).refLowestUpperBound(*right);
}

Type refLowestUpperBound(virtual!Type right, virtual!Type left);

@method
Type _refLowestUpperBound(Type left, Type right) {
    return null;
}

private Mutability lowestUpperBound(Mutability left, Mutability right) {
    return left == right ? left : Mutability.UNKNOWN;
}

@method
Type _refLowestUpperBound(ArrayType left, ArrayType right) {
    if (!left.modifiers.identified || !right.modifiers.identified) {
        return null;
    }
    if (!(*left).identical(*right)) {
        return null;
    }
    auto mutability = lowestUpperBound(left.modifiers.mutability, right.modifiers.mutability);
    auto commonSize = min(left.size, right.size);
    return new ArrayType(Modifiers(mutability, true), *left, commonSize);
}

@method
Type _refLowestUpperBound(TupleType left, TupleType right) {
    if (!left.modifiers.identified || !right.modifiers.identified) {
        return null;
    }
    auto mutability = lowestUpperBound(left.modifiers.mutability, right.modifiers.mutability);
    auto commonSize = min(left.size(), right.size());
    Type[] commonFields;
    foreach (i; 0 .. commonSize) {
        if (!left[i].identical(right[i])) {
            break;
        }
        commonFields ~= left[i];
    }
    return new TupleType(Modifiers(mutability, true), commonFields);
}

@method
Type _refLowestUpperBound(StructType left, StructType right) {
    if (!left.modifiers.identified || !right.modifiers.identified) {
        return null;
    }
    auto mutability = lowestUpperBound(left.modifiers.mutability, right.modifiers.mutability);
    Type[] commonFields;
    immutable(string)[] commonFieldNames;
    foreach (i, fieldName; left.fieldNames) {
        if (fieldName !in right || !left[i].identical(right[fieldName])) {
            continue;
        }
        commonFields ~= left[i];
        commonFieldNames ~= fieldName;
    }
    return new StructType(Modifiers(mutability, true), commonFields, commonFieldNames);
}
