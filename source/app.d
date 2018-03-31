import std.stdio : writeln;

import openmethods : updateMethods;

import pardus.type;
import pardus.mutable;
import pardus.identical;
import pardus.subtype;
import pardus.print;
import pardus.util;

void main() {
    updateMethods();

    writeln(BoolType.MUTABLE.print());
    writeln(IntType.UINT16.print());
    writeln(FloatType.FP64.print());
    auto tupleType = new TupleType(Modifiers.IMMUTABLE, [BoolType.MUTABLE, IntType.UINT16, FloatType.FP64]);
    writeln(tupleType.print());
    writeln(tupleType[$ - 1].print());
    writeln(new StructType(Modifiers.MUTABLE, [tupleType, FloatType.FP64], ["a", "b"]).print());
    writeln(new ArrayType(Modifiers.MUTABLE, FloatType.FP64, 16).print());
    writeln(new SliceType(Modifiers.MUTABLE, FloatType.FP32).print());
    writeln(new PointerType(Modifiers.MUTABLE, tupleType).print());
    writeln(new FunctionType(Modifiers.MUTABLE, [IntType.UINT32, IntType.SINT32], ["", ""], null).print());
    auto funcType = new FunctionType(Modifiers(Mutability.IMMUTABLE, true), [IntType.UINT32, IntType.SINT32], ["x", "y"], BoolType.MUTABLE);
    writeln(funcType.print());
    writeln(funcType["x"].print());

    auto link = new MutLinkType("T", null);
    auto selfRefType = new StructType(Modifiers(Mutability.UNKNOWN),
        [IntType.SINT32, new PointerType(Modifiers.MUTABLE, cast(immutable) link)], ["value", "next"]);
    link.link = selfRefType;
    writeln(selfRefType.print());
    auto linkImmu = cast(LinkType) *cast(PointerType) selfRefType["next"];
    writeln((cast(StructType) linkImmu.link)["value"].print());

    auto link2 = new MutLinkType("S", null);
    auto selfRefType2 = new StructType(Modifiers(Mutability.UNKNOWN),
        [IntType.SINT32, new PointerType(Modifiers.MUTABLE, cast(immutable) link2)], ["value", "next"]);
    link2.link = selfRefType2;
    writeln(selfRefType2.print());

    auto link3 = new MutLinkType("U", null);
    auto selfRefType3 = new StructType(Modifiers(Mutability.UNKNOWN),
            [IntType.SINT32, new PointerType(Modifiers.MUTABLE, new StructType(Modifiers(Mutability.UNKNOWN),
                [IntType.SINT32, new PointerType(Modifiers.MUTABLE, cast(immutable) link3)], ["value", "next"]))],
            ["value", "next"]);
    link3.link = selfRefType3;
    writeln(selfRefType3.print());

    auto mutualRefA = new MutLinkType("A", null);
    auto mutualRefB = new MutLinkType("B", null);
    auto mutualA = new StructType(Modifiers.MUTABLE,
        [new PointerType(Modifiers.MUTABLE, cast(immutable) mutualRefB)], ["b"]);
    auto mutualB = new StructType(Modifiers.MUTABLE,
        [new PointerType(Modifiers.MUTABLE, cast(immutable) mutualRefA)], ["a"]);
    mutualRefA.link = mutualA;
    mutualRefB.link = mutualB;
    writeln(mutualA.print());
    writeln(mutualB.print());

    auto mutualRefC = new MutLinkType("C", null);
    auto mutualRefD = new MutLinkType("B", null);
    auto mutualC = new StructType(Modifiers.MUTABLE,
        [new PointerType(Modifiers.MUTABLE, cast(immutable) mutualRefD)], ["b"]);
    auto mutualD = new StructType(Modifiers.MUTABLE,
        [new PointerType(Modifiers.MUTABLE, cast(immutable) mutualRefC)], ["a"]);
    mutualRefC.link = mutualC;
    mutualRefD.link = mutualD;
    writeln(mutualC.print());
    writeln(mutualD.print());

    writeln(LitBoolType.TRUE.print());
    writeln(new LitUIntType(12).print());
    writeln(new LitSIntType(-2).print());
    writeln(new LitFloatType(3.4e4).print());
    writeln(new LitTupleType([LitBoolType.FALSE, new LitSIntType(1337)]).print());
    writeln(new LitStructType([LitBoolType.FALSE, new LitSIntType(1337)], ["a", "b"]).print());
    writeln(new LitPointerType(new LitFloatType(1.542)).print());
    writeln(new LitSizeSliceType(Modifiers(Mutability.IMMUTABLE, true), IntType.SINT8, new LitUIntType(64)).print());

    writeln();

    writeln(selfRefType.identical(selfRefType2));
    writeln(selfRefType.identical(selfRefType3));
    writeln(selfRefType2.identical(selfRefType3));
    writeln(selfRefType2.identical(selfRefType3));

    writeln(!mutualA.identical(mutualB));
    writeln(!mutualD.identical(mutualC));

    writeln(mutualA.identical(mutualC));
    writeln(mutualD.identical(mutualB));

    writeln(!mutualB.identical(mutualC));
    writeln(!mutualA.identical(mutualD));

    writeln();

    writeln(BoolType.IMMUTABLE.makeValueMutable().print());
    writeln(new TupleType(Modifiers.IMMUTABLE, [BoolType.MUTABLE, IntType.UINT16, FloatType.FP64]).makeValueMutable().print());
    writeln(new StructType(Modifiers.IMMUTABLE, [BoolType.IMMUTABLE], ["a"]).makeValueMutable().print());
    writeln(new ArrayType(Modifiers.IMMUTABLE, BoolType.IMMUTABLE, 16).makeValueMutable().print());
    writeln(new SliceType(Modifiers.IMMUTABLE, BoolType.IMMUTABLE).makeValueMutable().print());
    writeln(new PointerType(Modifiers.IMMUTABLE, BoolType.IMMUTABLE).makeValueMutable().print());
    writeln(new FunctionType(Modifiers.IMMUTABLE, [BoolType.IMMUTABLE], [""], null).makeValueMutable().print());

    auto link4 = new MutLinkType("T", null);
    auto selfRefImmType = new StructType(Modifiers.IMMUTABLE,
        [BoolType.IMMUTABLE, new PointerType(Modifiers.IMMUTABLE, cast(immutable) link4)], ["value", "next"]);
    link4.link = selfRefImmType;
    writeln(selfRefImmType.makeValueMutable().print());
    writeln(selfRefImmType.makeValueMutable().tryCast!StructType()["next"].tryCast!PointerType().value.tryCast!LinkType().link.print());

    auto link5 = new MutLinkType("T", null);
    auto impossibleType = new StructType(Modifiers.IMMUTABLE, [cast(immutable) link5], ["t"]);
    link5.link = impossibleType;
    writeln(impossibleType.makeValueMutable().print());
    writeln(impossibleType.makeValueMutable().tryCast!StructType()["t"].tryCast!LinkType().link.print());

    auto link6 = new MutLinkType("D", new ArrayType(Modifiers.IMMUTABLE, BoolType.IMMUTABLE, 16));
    auto dumbType = new StructType(Modifiers.IMMUTABLE, [cast(immutable) link6], ["d"]);
    writeln(dumbType.makeValueMutable().print());
    writeln(dumbType.makeValueMutable().tryCast!StructType()["d"].tryCast!LinkType().link.print());

    writeln();

    writeln(LitBoolType.TRUE.subtype(BoolType.MUTABLE));
    writeln(new LitSIntType(long.min).subtype(IntType.SINT64) == true);
    writeln(new LitSIntType(long.max).subtype(IntType.SINT64) == true);
    writeln(new LitUIntType(ulong.min).subtype(IntType.SINT64) == true);
    writeln(new LitUIntType(ulong.max).subtype(IntType.SINT64) == false);
    writeln(new LitSIntType(long.min).subtype(IntType.UINT64) == false);
    writeln(new LitSIntType(long.max).subtype(IntType.UINT64) == true);
    writeln(new LitUIntType(ulong.min).subtype(IntType.UINT64) == true);
    writeln(new LitUIntType(ulong.max).subtype(IntType.UINT64) == true);

    writeln(new LitSIntType(-120000).subtype(IntType.UINT16) == false);
    writeln(new LitUIntType(120000).subtype(IntType.UINT16) == false);

    writeln(new LitFloatType(-65504.0).subtype(FloatType.FP16) == true);
    writeln(new LitFloatType(65504.0).subtype(FloatType.FP16) == true);
    writeln(new LitFloatType(-float.max).subtype(FloatType.FP32) == true);
    writeln(new LitFloatType(float.max).subtype(FloatType.FP32) == true);
    writeln(new LitFloatType(-double.max).subtype(FloatType.FP64) == true);
    writeln(new LitFloatType(double.max).subtype(FloatType.FP64) == true);

    writeln(new LitSIntType(-120000).subtype(FloatType.FP16) == false);
    writeln(new LitUIntType(120000).subtype(FloatType.FP16) == false);

    writeln(IntType.SINT8.subtype(IntType.SINT8) == true);
    writeln(IntType.SINT8.subtype(IntType.UINT8) == false);
    writeln(IntType.SINT8.subtype(IntType.UINT64) == false);
    writeln(IntType.UINT8.subtype(IntType.SINT16) == true);
    writeln(IntType.SINT32.subtype(IntType.SINT64) == true);

    writeln(FloatType.FP16.subtype(FloatType.FP16) == true);
    writeln(FloatType.FP32.subtype(FloatType.FP16) == false);
    writeln(FloatType.FP32.subtype(FloatType.FP64) == true);
}
