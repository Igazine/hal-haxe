package hank.ext;

import hank.Types;

class SysExtension implements IExtension {
    public var name(default, null):String;
    public function get_name():String return "SysExtension";

    public function new() {}

    public function getModules():Map<String, Map<String, Array<Value>->ExecutionContext->Value>> {
        var valToString = (v:Value) -> ValueTools.toString(v);
        var mods = new Map<String, Map<String, Array<Value>->ExecutionContext->Value>>();

        // --- host ---
        mods.set("host", [
            "cwd" => (args, ctx) -> VString(Sys.getCwd()),
            "isRoot" => (args, ctx) -> {
                #if (linux || macos || bsd)
                try {
                    var p = new sys.io.Process("id", ["-u"]);
                    var out = p.stdout.readAll().toString();
                    p.close();
                    return Std.trim(out) == "0" ? VNumber(1.0) : VVoid;
                } catch (e:Dynamic) return VVoid;
                #else
                return VVoid;
                #end
            },
            "pid" => (args, ctx) -> {
                #if (linux || macos || windows || bsd)
                return VNumber(Sys.programPath() != null ? 0 : 0); // Placeholder, Haxe Sys doesn't have PID easily
                #else
                return VVoid;
                #end
            }
        ]);

        // --- os ---
        mods.set("os", [
            "type" => (args, ctx) -> {
                var name = Sys.systemName().toLowerCase();
                if (StringTools.contains(name, "window")) return VString("windows");
                if (StringTools.contains(name, "linux")) return VString("linux");
                if (StringTools.contains(name, "mac") || StringTools.contains(name, "darwin")) return VString("darwin");
                if (StringTools.contains(name, "bsd")) return VString("bsd");
                return VString("unknown");
            },
            "name" => (args, ctx) -> VString(Sys.systemName()),
            "arch" => (args, ctx) -> VString("unknown"), // Haxe doesn't provide arch easily
            "memory" => (args, ctx) -> {
                var map = new Map<String, Value>();
                map.set("total", VNumber(0));
                map.set("free", VNumber(0));
                map.set("used", VNumber(0));
                return VObject(map);
            },
            "cpu" => (args, ctx) -> VNumber(0.0)
        ]);

        // --- fs ---
        mods.set("fs", [
            "exists" => (args, ctx) -> (args.length > 0 && sys.FileSystem.exists(valToString(args[0]))) ? VNumber(1.0) : VVoid,
            "isDir" => (args, ctx) -> (args.length > 0 && sys.FileSystem.isDirectory(valToString(args[0]))) ? VNumber(1.0) : VVoid,
            "absPath" => (args, ctx) -> args.length == 0 ? VVoid : VString(sys.FileSystem.fullPath(valToString(args[0]))),
            "read" => (args, ctx) -> {
                if (args.length == 0) return VVoid;
                try {
                    return VString(sys.io.File.getContent(valToString(args[0])));
                } catch (e:Dynamic) return VVoid;
            },
            "write" => (args, ctx) -> {
                if (args.length < 2) return VVoid;
                try {
                    sys.io.File.saveContent(valToString(args[0]), valToString(args[1]));
                    return VNumber(1.0);
                } catch (e:Dynamic) return VVoid;
            },
            "append" => (args, ctx) -> {
                if (args.length < 2) return VVoid;
                try {
                    var o = sys.io.File.append(valToString(args[0]));
                    o.writeString(valToString(args[1]));
                    o.close();
                    return VNumber(1.0);
                } catch (e:Dynamic) return VVoid;
            },
            "copy" => (args, ctx) -> {
                if (args.length < 2) return VVoid;
                try {
                    sys.io.File.copy(valToString(args[0]), valToString(args[1]));
                    return VNumber(1.0);
                } catch (e:Dynamic) return VVoid;
            },
            "move" => (args, ctx) -> {
                if (args.length < 2) return VVoid;
                try {
                    sys.FileSystem.rename(valToString(args[0]), valToString(args[1]));
                    return VNumber(1.0);
                } catch (e:Dynamic) return VVoid;
            },
            "deleteFile" => (args, ctx) -> {
                if (args.length == 0) return VVoid;
                try {
                    sys.FileSystem.deleteFile(valToString(args[0]));
                    return VNumber(1.0);
                } catch (e:Dynamic) return VVoid;
            },
            "deleteDir" => (args, ctx) -> {
                if (args.length == 0) return VVoid;
                try {
                    sys.FileSystem.deleteDirectory(valToString(args[0]));
                    return VNumber(1.0);
                } catch (e:Dynamic) return VVoid;
            },
            "mkdir" => (args, ctx) -> {
                if (args.length == 0) return VVoid;
                try {
                    sys.FileSystem.createDirectory(valToString(args[0]));
                    return VNumber(1.0);
                } catch (e:Dynamic) return VVoid;
            },
            "list" => (args, ctx) -> {
                var path = args.length > 0 ? valToString(args[0]) : ".";
                try {
                    return VArray(sys.FileSystem.readDirectory(path).map(s -> VString(s)));
                } catch (e:Dynamic) return VVoid;
            },
            "stat" => (args, ctx) -> {
                if (args.length == 0) return VVoid;
                try {
                    var s = sys.FileSystem.stat(valToString(args[0]));
                    var map = new Map<String, Value>();
                    map.set("size", VNumber(s.size));
                    map.set("isDir", sys.FileSystem.isDirectory(valToString(args[0])) ? VNumber(1.0) : VVoid);
                    map.set("mtime", VNumber(s.mtime.getTime()));
                    return VObject(map);
                } catch (e:Dynamic) return VVoid;
            }
        ]);

        // --- proc ---
        mods.set("proc", [
            "run" => (args, ctx) -> {
                if (args.length == 0) return VVoid;
                var cmd = valToString(args[0]);
                var cmdArgs:Array<String> = [];
                if (args.length > 1) switch (args[1]) {
                    case VArray(a): cmdArgs = a.map(valToString);
                    default:
                }
                try {
                    var p = new sys.io.Process(cmd, cmdArgs);
                    var stdout = p.stdout.readAll().toString();
                    var stderr = p.stderr.readAll().toString();
                    var code = p.exitCode();
                    p.close();
                    var map = new Map<String, Value>();
                    map.set("code", VNumber(code));
                    map.set("stdout", VString(stdout));
                    map.set("stderr", VString(stderr));
                    return VObject(map);
                } catch (e:Dynamic) return VVoid;
            }
        ]);

        return mods;
    }
}
