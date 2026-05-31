package hank.ext;

import hank.Types;

class SysExtension implements IExtension {
    public var name(default, null):String = "SysExtension";

    public function new() {}

    public function getTasks():Map<String, Array<Value>->ExecutionContext->Value> {
        var valToString = (v:Value) -> ValueTools.toString(v);
        var tasks = new Map<String, Array<Value>->ExecutionContext->Value>();

        // --- host ---
        tasks.set("host_cwd", (args, ctx) -> VString(Sys.getCwd()));
        tasks.set("host_isRoot", (args, ctx) -> {
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
        });
        tasks.set("host_pid", (args, ctx) -> {
            #if (linux || macos || windows || bsd)
            return VNumber(0); // Placeholder
            #else
            return VVoid;
            #end
        });

        // --- os ---
        tasks.set("os_type", (args, ctx) -> {
            var name = Sys.systemName().toLowerCase();
            if (StringTools.contains(name, "window")) return VString("windows");
            if (StringTools.contains(name, "linux")) return VString("linux");
            if (StringTools.contains(name, "mac") || StringTools.contains(name, "darwin")) return VString("darwin");
            if (StringTools.contains(name, "bsd")) return VString("bsd");
            return VString("unknown");
        });
        tasks.set("os_name", (args, ctx) -> VString(Sys.systemName()));
        tasks.set("os_arch", (args, ctx) -> VString("unknown"));
        tasks.set("os_memory", (args, ctx) -> {
            var map = new Map<String, Value>();
            map.set("total", VNumber(0));
            map.set("free", VNumber(0));
            map.set("used", VNumber(0));
            return VMap(map);
        });
        tasks.set("os_cpu", (args, ctx) -> VNumber(0.0));

        // --- fs ---
        tasks.set("fs_exists", (args, ctx) -> {
            if (args.length == 0) return VVoid;
            var path = "";
            switch (args[0]) {
                case VString(s): path = s;
                case other: return VError(4007, [VString("String"), VString(ValueTools.typeToString(ValueTools.getType(other))), VString("fs_exists")]);
            }
            return sys.FileSystem.exists(path) ? VNumber(1.0) : VVoid;
        });
        tasks.set("fs_isDir", (args, ctx) -> {
            if (args.length == 0) return VVoid;
            var path = "";
            switch (args[0]) {
                case VString(s): path = s;
                case other: return VError(4007, [VString("String"), VString(ValueTools.typeToString(ValueTools.getType(other))), VString("fs_isDir")]);
            }
            return sys.FileSystem.isDirectory(path) ? VNumber(1.0) : VVoid;
        });
        tasks.set("fs_absPath", (args, ctx) -> {
            if (args.length == 0) return VVoid;
            var path = "";
            switch (args[0]) {
                case VString(s): path = s;
                case other: return VError(4007, [VString("String"), VString(ValueTools.typeToString(ValueTools.getType(other))), VString("fs_absPath")]);
            }
            return VString(sys.FileSystem.fullPath(path));
        });
        tasks.set("fs_read", (args, ctx) -> {
            if (args.length == 0) return VVoid;
            var path = "";
            switch (args[0]) {
                case VString(s): path = s;
                case other: return VError(4007, [VString("String"), VString(ValueTools.typeToString(ValueTools.getType(other))), VString("fs_read")]);
            }
            try {
                return VString(sys.io.File.getContent(path));
            } catch (e:Dynamic) return VVoid;
        });
        tasks.set("fs_write", (args, ctx) -> {
            if (args.length < 2) return VVoid;
            var path = "";
            var content = "";
            switch (args[0]) {
                case VString(s): path = s;
                case other: return VError(4007, [VString("String"), VString(ValueTools.typeToString(ValueTools.getType(other))), VString("fs_write")]);
            }
            switch (args[1]) {
                case VString(s): content = s;
                case other: return VError(4007, [VString("String"), VString(ValueTools.typeToString(ValueTools.getType(other))), VString("fs_write")]);
            }
            try {
                sys.io.File.saveContent(path, content);
                return VNumber(1.0);
            } catch (e:Dynamic) return VVoid;
        });
        tasks.set("fs_deleteFile", (args, ctx) -> {
            if (args.length == 0) return VVoid;
            var path = "";
            switch (args[0]) {
                case VString(s): path = s;
                case other: return VError(4007, [VString("String"), VString(ValueTools.typeToString(ValueTools.getType(other))), VString("fs_deleteFile")]);
            }
            try {
                sys.FileSystem.deleteFile(path);
                return VNumber(1.0);
            } catch (e:Dynamic) return VVoid;
        });
        tasks.set("fs_stat", (args, ctx) -> {
            if (args.length == 0) return VVoid;
            var path = "";
            switch (args[0]) {
                case VString(s): path = s;
                case other: return VError(4007, [VString("String"), VString(ValueTools.typeToString(ValueTools.getType(other))), VString("fs_stat")]);
            }
            try {
                var s = sys.FileSystem.stat(path);
                var map = new Map<String, Value>();
                map.set("size", VNumber(s.size));
                map.set("isDir", sys.FileSystem.isDirectory(path) ? VNumber(1.0) : VVoid);
                map.set("mtime", VNumber(s.mtime.getTime()));
                return VMap(map);
            } catch (e:Dynamic) return VVoid;
        });

        // --- proc ---
        tasks.set("proc_run", (args, ctx) -> {
            if (args.length == 0) return VVoid;
            var cmd = "";
            switch (args[0]) {
                case VString(s): cmd = s;
                case other: return VError(4007, [VString("String"), VString(ValueTools.typeToString(ValueTools.getType(other))), VString("proc_run")]);
            }
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
                return VMap(map);
            } catch (e:Dynamic) return VVoid;
        });

        return tasks;
    }
}
