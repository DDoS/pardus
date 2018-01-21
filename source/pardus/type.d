module pardus.type;

import std.algorithm.searching : countUntil;
import std.format : format;
import std.typecons : Rebindable, Nullable;

import pardus.util;

enum Mutability {
    MUTABLE,
    IMMUTABLE,
    UNKNOWN
}

alias Type = immutable _Type;
abstract class _Type {
}

struct Modifiers {
    static immutable Modifiers MUTABLE = Modifiers(Mutability.MUTABLE);
    static immutable Modifiers IMMUTABLE = Modifiers(Mutability.IMMUTABLE);
    Mutability mutability;
}

alias DefinedType = immutable _DefinedType;
abstract class _DefinedType : Type {
    immutable Modifiers modifiers;

    protected this(Modifiers modifiers) immutable {
        this.modifiers = modifiers;
    }
}

alias AtomicType = immutable _AtomicType;
abstract class _AtomicType : DefinedType {
    protected this(Modifiers modifiers) immutable {
        super(modifiers);
    }
}

alias CompositeType = immutable _CompositeType;
abstract class _CompositeType : DefinedType {
    protected this(Modifiers modifiers) immutable {
        super(modifiers);
    }
}

alias BoolType = immutable _BoolType;
class _BoolType : AtomicType {
    static BoolType MUTABLE = new BoolType(Modifiers.MUTABLE);

    private this(Modifiers modifiers) immutable {
        super(modifiers);
    }
}

alias IntType = immutable _IntType;
class _IntType : AtomicType {
    static IntType UINT8 = new IntType(Modifiers.MUTABLE, 1, false);
    static IntType SINT8 = new IntType(Modifiers.MUTABLE, 1, true);
    static IntType UINT16 = new IntType(Modifiers.MUTABLE, 2, false);
    static IntType SINT16 = new IntType(Modifiers.MUTABLE, 2, true);
    static IntType UINT32 = new IntType(Modifiers.MUTABLE, 4, false);
    static IntType SINT32 = new IntType(Modifiers.MUTABLE, 4, true);
    static IntType UINT64 = new IntType(Modifiers.MUTABLE, 8, false);
    static IntType SINT64 = new IntType(Modifiers.MUTABLE, 8, true);

    immutable size_t bytes;
    immutable bool signed;
    immutable string name;

    private this(Modifiers modifiers, size_t bytes, bool signed) immutable {
        super(modifiers);
        this.bytes = bytes;
        this.signed = signed;
        name = "%cint%d".format(signed ? 's' : 'u', bits);
    }

    @property size_t bits() immutable {
        return bytes * 8;
    }
}

alias FloatType = immutable _FloatType;
class _FloatType : AtomicType {
    static FloatType FP16 = new FloatType(Modifiers.MUTABLE, 2);
    static FloatType FP32 = new FloatType(Modifiers.MUTABLE, 4);
    static FloatType FP64 = new FloatType(Modifiers.MUTABLE, 8);

    immutable size_t bytes;
    immutable string name;

    private this(Modifiers modifiers, size_t bytes) immutable {
        super(modifiers);
        this.bytes = bytes;
        name = "fp%d".format(bits);
    }

    @property size_t bits() immutable {
        return bytes * 8;
    }
}

alias TupleType = immutable _TupleType;
class _TupleType : CompositeType {
    immutable Type[] fields;

    this(Modifiers modifiers, Type[] fields) immutable {
        super(modifiers);
        this.fields = fields;
    }

    @property size_t size() inout {
        return fields.length;
    }

    Type opIndex(size_t index) inout {
        return fields[index];
    }

    size_t opDollar(size_t pos : 0)() inout {
        return fields.length;
    }
}

alias StructType = immutable _StructType;
class _StructType : TupleType {
    immutable string[] fieldNames;

    this(Modifiers modifiers, Type[] fields, immutable string[] fieldNames) immutable {
        assert(fields.length == fieldNames.length);
        super(modifiers, fields);
        this.fieldNames = fieldNames;
    }

    Type opIndex(string name) inout {
        return super.opIndex(fieldNames.countUntil(name));
    }
}

private mixin template opDeref(alias returnSymbol) {
    auto opUnary(string s : "*")() inout {
        return returnSymbol;
    }
}

alias ArrayType = immutable _ArrayType;
class _ArrayType : CompositeType {
    immutable Type component;
    immutable ulong size;

    this(Modifiers modifiers, Type component, ulong size) immutable {
        super(modifiers);
        this.component = component;
        this.size = size;
    }

    mixin opDeref!component;
}

alias SliceType = immutable _SliceType;
class _SliceType : CompositeType {
    immutable Type component;

    this(Modifiers modifiers, Type component) immutable {
        super(modifiers);
        this.component = component;
    }

    mixin opDeref!component;
}

alias PointerType = immutable _PointerType;
class _PointerType : CompositeType {
    immutable Type value;

    this(Modifiers modifiers, Type value) immutable {
        super(modifiers);
        this.value = value;
    }

    mixin opDeref!value;
}

alias FunctionType = immutable _FunctionType;
class _FunctionType : DefinedType {
    immutable Type[] params;
    immutable string[] paramNames;
    immutable Type ret;

    this(Modifiers modifiers, Type[] params, immutable string[] paramNames, Type ret) immutable {
        assert(params.length == paramNames.length);
        super(modifiers);
        this.params = params;
        this.paramNames = paramNames;
        this.ret = ret;
    }

    Type opIndex(size_t index) inout {
        return params[index];
    }

    Type opIndex(string name) inout {
        return opIndex(paramNames.countUntil(name));
    }

    size_t opDollar(size_t pos : 0)() inout {
        return params.length;
    }
}

alias BackRefType = immutable MutBackRefType;
class MutBackRefType : Type {
    immutable string name;
    Rebindable!Type backRef;

    this(string name, Type backRef) {
        this.name = name;
        this.backRef = backRef;
    }
}

alias LitType = immutable _LitType;
abstract class _LitType : Type {
}

alias LitBoolType = immutable _LitBoolType;
class _LitBoolType : LitType {
    static LitBoolType TRUE = new LitBoolType(true);
    static LitBoolType FALSE = new LitBoolType(true);

    immutable bool value;

    private this(bool value) immutable {
        this.value = value;
    }
}

alias LitUIntType = immutable _LitUIntType;
class _LitUIntType : LitType {
    immutable ulong value;

    this(ulong value) immutable {
        this.value = value;
    }
}

alias LitSIntType = immutable _LitSIntType;
class _LitSIntType : LitType {
    immutable long value;

    this(long value) immutable {
        this.value = value;
    }
}

alias LitFloatType = immutable _LitFloatType;
class _LitFloatType : LitType {
    immutable double value;

    this(double value) immutable {
        this.value = value;
    }
}

alias LitTupleType = immutable _LitTupleType;
class _LitTupleType : LitType {
    immutable LitType[] fields;

    this(LitType[] fields) immutable {
        this.fields = fields;
    }

    @property size_t size() inout {
        return fields.length;
    }

    LitType opIndex(size_t index) inout {
        return fields[index];
    }

    size_t opDollar(size_t pos : 0)() inout {
        return fields.length;
    }
}

alias LitStructType = immutable _LitStructType;
class _LitStructType : LitTupleType {
    immutable string[] fieldNames;

    this(LitType[] fields, immutable string[] fieldNames) immutable {
        assert(fields.length == fieldNames.length);
        super(fields);
        this.fieldNames = fieldNames;
    }

    LitType opIndex(string name) inout {
        return super.opIndex(fieldNames.countUntil(name));
    }
}

alias LitPointerType = immutable _LitPointerType;
class _LitPointerType : LitType {
    immutable LitType value;

    this(LitType value) immutable {
        this.value = value;
    }

    mixin opDeref!value;
}

alias LitSizeSliceType = immutable _LitSizeSliceType;
class _LitSizeSliceType : CompositeType {
    immutable Type component;
    immutable LitUIntType size;

    this(Modifiers modifiers, Type component, LitUIntType size) immutable {
        super(modifiers);
        this.component = component;
        this.size = size;
    }

    mixin opDeref!component;
}
