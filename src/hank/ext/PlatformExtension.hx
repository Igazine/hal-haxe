package hank.ext;

import hank.Types;

class PlatformExtension implements IExtension {
    public var name(default, null):String;
    public function get_name():String return "PlatformExtension";

    public function new() {}

    private static inline var SAFE_INT_MAX:Float = 9007199254740991.0;

    private static function checkSafeInt(n:Float):haxe.Int64 {
        if (Math.abs(n) > SAFE_INT_MAX || !Math.isFinite(n)) {
            throw HankErrorRegistry.create(BitwiseOutOfBounds, [n]);
        }
        return haxe.Int64.fromFloat(n);
    }

    private static function fromSafeInt(n:haxe.Int64):Float {
        var f = Std.parseFloat(haxe.Int64.toStr(n));
        if (Math.abs(f) > SAFE_INT_MAX) {
            throw HankErrorRegistry.create(BitwiseOutOfBounds, [f]);
        }
        return f;
    }

    public function getModules():Map<String, Map<String, Array<Value>->ExecutionContext->Value>> {
        var mods = new Map<String, Map<String, Array<Value>->ExecutionContext->Value>>();

        mods.set("bin", [
            "and" => (args, ctx) -> {
                var a = 0.0; switch (args[0]) { case VNumber(n): a = n; default: }
                var b = 0.0; switch (args[1]) { case VNumber(n): b = n; default: }
                return VNumber(fromSafeInt(checkSafeInt(a) & checkSafeInt(b)));
            },
            "or" => (args, ctx) -> {
                var a = 0.0; switch (args[0]) { case VNumber(n): a = n; default: }
                var b = 0.0; switch (args[1]) { case VNumber(n): b = n; default: }
                return VNumber(fromSafeInt(checkSafeInt(a) | checkSafeInt(b)));
            },
            "xor" => (args, ctx) -> {
                var a = 0.0; switch (args[0]) { case VNumber(n): a = n; default: }
                var b = 0.0; switch (args[1]) { case VNumber(n): b = n; default: }
                return VNumber(fromSafeInt(checkSafeInt(a) ^ checkSafeInt(b)));
            },
            "not" => (args, ctx) -> {
                var a = 0.0; switch (args[0]) { case VNumber(n): a = n; default: }
                return VNumber(fromSafeInt(~checkSafeInt(a)));
            },
            "shiftL" => (args, ctx) -> {
                var a = 0.0; switch (args[0]) { case VNumber(n): a = n; default: }
                var b = 0.0; switch (args[1]) { case VNumber(n): b = n; default: }
                return VNumber(fromSafeInt(checkSafeInt(a) << haxe.Int64.toInt(checkSafeInt(b))));
            },
            "shiftR" => (args, ctx) -> {
                var a = 0.0; switch (args[0]) { case VNumber(n): a = n; default: }
                var b = 0.0; switch (args[1]) { case VNumber(n): b = n; default: }
                return VNumber(fromSafeInt(checkSafeInt(a) >> haxe.Int64.toInt(checkSafeInt(b))));
            }
        ]);

        return mods;
    }
}
