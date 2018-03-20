module pardus.mutable;

import std.typecons : Rebindable;

import openmethods: registerMethods, virtual, method;

import pardus.type;
import pardus.cycle;
import pardus.util;

mixin(registerMethods);

private alias TypeCycles = Cycles!(CompositeType, 1);

// Bug with openmethods: ref cannot be used, work around with class type as wrapper
private class BrokenLinks {
    MutLinkType[CompositeType] broken;

    auto opBinaryRight(string op : "in")(CompositeType type) {
        return type in broken;
    }

    void opIndexAssign(MutLinkType link, CompositeType type) {
        broken[type] = link;
    }
}

Type makeValueMutable(Type type) {
    return makeValueMutable(type, new TypeCycles(), new BrokenLinks());
}

Type makeValueMutable(virtual!Type type, TypeCycles cycles, BrokenLinks broken);

@method
Type _makeValueMutable(Type type, TypeCycles cycles, BrokenLinks broken) {
    return type;
}

@method
BoolType _makeValueMutable(BoolType type, TypeCycles cycles, BrokenLinks broken) {
    return BoolType.MUTABLE;
}

@method
IntType _makeValueMutable(IntType type, TypeCycles cycles, BrokenLinks broken) {
    return new IntType(Modifiers.MUTABLE, type.bytes, type.signed);
}

@method
FloatType _makeValueMutable(FloatType type, TypeCycles cycles, BrokenLinks broken) {
    return new FloatType(Modifiers.MUTABLE, type.bytes);
}

private Type[] makeValueMutable(Type[] fields, TypeCycles cycles, BrokenLinks broken) {
    Type[] mutable;
    mutable.reserve(fields.length);
    foreach (field; fields) {
        mutable ~= field.makeValueMutable(cycles, broken);
    }
    return mutable;
}

@method
TupleType _makeValueMutable(TupleType type, TypeCycles cycles, BrokenLinks broken) {
    cycles.traverse(type);
    auto mutable = new TupleType(Modifiers.MUTABLE, type.fields.makeValueMutable(cycles, broken));
    if (auto brokenLink = type in broken) {
        brokenLink.link = mutable;
    }
    return mutable;
}

@method
StructType _makeValueMutable(StructType type, TypeCycles cycles, BrokenLinks broken) {
    cycles.traverse(type);
    auto mutable = new StructType(Modifiers.MUTABLE, type.fields.makeValueMutable(cycles, broken), type.fieldNames);
    if (auto brokenLink = type in broken) {
        brokenLink.link = mutable;
    }
    return mutable;
}

@method
ArrayType _makeValueMutable(ArrayType type, TypeCycles cycles, BrokenLinks broken) {
    cycles.traverse(type);
    auto mutable = new ArrayType(Modifiers.MUTABLE, type.component.makeValueMutable(cycles, broken), type.size);
    if (auto brokenLink = type in broken) {
        brokenLink.link = mutable;
    }
    return mutable;
}

@method
SliceType _makeValueMutable(SliceType type, TypeCycles cycles, BrokenLinks broken) {
    cycles.traverse(type);
    auto mutable = new SliceType(Modifiers.MUTABLE, type.component);
    if (auto brokenLink = type in broken) {
        brokenLink.link = mutable;
    }
    return mutable;
}

@method
PointerType _makeValueMutable(PointerType type, TypeCycles cycles, BrokenLinks broken) {
    cycles.traverse(type);
    auto mutable = new PointerType(Modifiers.MUTABLE, type.value);
    if (auto brokenLink = type in broken) {
        brokenLink.link = mutable;
    }
    return mutable;
}

@method
FunctionType _makeValueMutable(FunctionType type, TypeCycles cycles, BrokenLinks broken) {
    return new FunctionType(Modifiers.MUTABLE, type.params, type.paramNames, type.ret);
}

@method
LinkType _makeValueMutable(LinkType type, TypeCycles cycles, BrokenLinks broken) {
    if (cycles.traverse(type.link)) {
        auto brokenLink = new MutLinkType(type.name, null);
        broken[type.link] = brokenLink;
        return cast(immutable) brokenLink;
    }
    auto mutable = type.link.makeValueMutable(cycles, broken).tryCast!CompositeType();
    return cast(immutable) new MutLinkType(type.name, mutable);
}
