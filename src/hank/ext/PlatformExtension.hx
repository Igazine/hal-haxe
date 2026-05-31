package hank.ext;

import hank.Types;

class PlatformExtension implements IExtension {
    public var name(default, null):String = "PlatformExtension";

    public function new() {}

    private static inline var SAFE_INT_MAX:Float = 9007199254740991.0;

    private static function checkSafeInt(n:Float, taskName:String):Value {
        if (Math.abs(n) > SAFE_INT_MAX || !Math.isFinite(n)) {
            return VError(4005, [VNumber(n), VString(taskName)]);
        }
        return VVoid; // Success signal
    }

    private static function fromSafeInt(n:haxe.Int64, taskName:String):Value {
        var f = Std.parseFloat(haxe.Int64.toStr(n));
        if (Math.abs(f) > SAFE_INT_MAX) {
            return VError(4005, [VNumber(f), VString(taskName)]);
        }
        return VNumber(f);
    }

    public function getTasks():Map<String, Array<Value>->ExecutionContext->Value> {
        var tasks = new Map<String, Array<Value>->ExecutionContext->Value>();

        tasks.set("bin_and", (args, ctx) -> {
            var a:Float = 0;
            var b:Float = 0;
            if (args.length < 2) return VVoid;
            switch (args[0]) {
                case VNumber(n): a = n;
                case other: return VError(4007, [VString("Number"), VString(ValueTools.typeToString(ValueTools.getType(other))), VString("bin_and")]);
            }
            switch (args[1]) {
                case VNumber(n): b = n;
                case other: return VError(4007, [VString("Number"), VString(ValueTools.typeToString(ValueTools.getType(other))), VString("bin_and")]);
            }

            var err = checkSafeInt(a, "bin_and");
            if (ctx.isError(err)) return err;
            err = checkSafeInt(b, "bin_and");
            if (ctx.isError(err)) return err;

            return fromSafeInt(haxe.Int64.fromFloat(a) & haxe.Int64.fromFloat(b), "bin_and");
        });

        tasks.set("bin_or", (args, ctx) -> {
            var a:Float = 0;
            var b:Float = 0;
            if (args.length < 2) return VVoid;
            switch (args[0]) {
                case VNumber(n): a = n;
                case other: return VError(4007, [VString("Number"), VString(ValueTools.typeToString(ValueTools.getType(other))), VString("bin_or")]);
            }
            switch (args[1]) {
                case VNumber(n): b = n;
                case other: return VError(4007, [VString("Number"), VString(ValueTools.typeToString(ValueTools.getType(other))), VString("bin_or")]);
            }

            var err = checkSafeInt(a, "bin_or");
            if (ctx.isError(err)) return err;
            err = checkSafeInt(b, "bin_or");
            if (ctx.isError(err)) return err;

            return fromSafeInt(haxe.Int64.fromFloat(a) | haxe.Int64.fromFloat(b), "bin_or");
        });

        tasks.set("bin_xor", (args, ctx) -> {
            var a:Float = 0;
            var b:Float = 0;
            if (args.length < 2) return VVoid;
            switch (args[0]) {
                case VNumber(n): a = n;
                case other: return VError(4007, [VString("Number"), VString(ValueTools.typeToString(ValueTools.getType(other))), VString("bin_xor")]);
            }
            switch (args[1]) {
                case VNumber(n): b = n;
                case other: return VError(4007, [VString("Number"), VString(ValueTools.typeToString(ValueTools.getType(other))), VString("bin_xor")]);
            }

            var err = checkSafeInt(a, "bin_xor");
            if (ctx.isError(err)) return err;
            err = checkSafeInt(b, "bin_xor");
            if (ctx.isError(err)) return err;

            return fromSafeInt(haxe.Int64.fromFloat(a) ^ haxe.Int64.fromFloat(b), "bin_xor");
        });

        tasks.set("bin_not", (args, ctx) -> {
            var a:Float = 0;
            if (args.length < 1) return VVoid;
            switch (args[0]) {
                case VNumber(n): a = n;
                case other: return VError(4007, [VString("Number"), VString(ValueTools.typeToString(ValueTools.getType(other))), VString("bin_not")]);
            }
            var err = checkSafeInt(a, "bin_not");
            if (ctx.isError(err)) return err;

            return fromSafeInt(~haxe.Int64.fromFloat(a), "bin_not");
        });

        tasks.set("bin_shiftL", (args, ctx) -> {
            var a:Float = 0;
            var b:Int = 0;
            if (args.length < 2) return VVoid;
            switch (args[0]) {
                case VNumber(n): a = n;
                case other: return VError(4007, [VString("Number"), VString(ValueTools.typeToString(ValueTools.getType(other))), VString("bin_shiftL")]);
            }
            switch (args[1]) {
                case VNumber(n): b = Std.int(n);
                case other: return VError(4007, [VString("Number"), VString(ValueTools.typeToString(ValueTools.getType(other))), VString("bin_shiftL")]);
            }

            var err = checkSafeInt(a, "bin_shiftL");
            if (ctx.isError(err)) return err;

            return fromSafeInt(haxe.Int64.fromFloat(a) << b, "bin_shiftL");
        });

        tasks.set("bin_shiftR", (args, ctx) -> {
            var a:Float = 0;
            var b:Int = 0;
            if (args.length < 2) return VVoid;
            switch (args[0]) {
                case VNumber(n): a = n;
                case other: return VError(4007, [VString("Number"), VString(ValueTools.typeToString(ValueTools.getType(other))), VString("bin_shiftR")]);
            }
            switch (args[1]) {
                case VNumber(n): b = Std.int(n);
                case other: return VError(4007, [VString("Number"), VString(ValueTools.typeToString(ValueTools.getType(other))), VString("bin_shiftR")]);
            }

            var err = checkSafeInt(a, "bin_shiftR");
            if (ctx.isError(err)) return err;

            return fromSafeInt(haxe.Int64.fromFloat(a) >> b, "bin_shiftR");
        });

        return tasks;
    }
}
