import std.stdio : writeln;

import openmethods : updateMethods;

import pardus.type;
import pardus.print;

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
    auto funcType = new FunctionType(Modifiers.MUTABLE, [IntType.UINT32, IntType.SINT32], ["x", "y"], BoolType.MUTABLE);
    writeln(funcType.print());
    writeln(funcType["x"].print());

    auto backRef = new MutBackRefType("T", null);
    auto selfRefType = new StructType(Modifiers(Mutability.UNKNOWN),
            [IntType.SINT32, new PointerType(Modifiers.MUTABLE, cast(immutable) backRef)], ["value", "next"]);
    backRef.backRef = selfRefType;
    writeln(selfRefType.print());
    auto backRefImmu = cast(BackRefType) *cast(PointerType) selfRefType["next"];
    writeln((cast(StructType) backRefImmu.backRef)["value"].print());
}
