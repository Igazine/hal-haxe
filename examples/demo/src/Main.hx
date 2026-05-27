package;

import hal.Types;
import hal.Runner;
import hal.StdLib;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

class DemoRunner extends Runner {
    override function readFile(path:String):String {
        return File.getContent(path);
    }

    override function resolvePath(macroPath:String, baseFile:String):String {
        if (Path.isAbsolute(macroPath)) return macroPath;
        
        var baseDir = (baseFile == "" || baseFile == null) ? Sys.getCwd() : Path.directory(baseFile);
        var joined = Path.join([baseDir, macroPath]);
        
        if (Path.extension(joined) == "") {
            if (FileSystem.exists(joined + ".hal")) return Path.normalize(joined + ".hal");
        }
        return Path.normalize(joined);
    }
}

class Main {
    static function main() {
        var args = Sys.args();
        var current = Sys.getCwd();
        
        // Submodule is at vendor/hal relative to the hal-haxe root.
        var workspaceRoot = Path.normalize(Path.join([current, "vendor/hal"]));
        if (!FileSystem.exists(workspaceRoot)) {
            workspaceRoot = Path.normalize(Path.join([current, "../../vendor/hal"]));
        }

        if (args.length == 0) {
            runConformance(workspaceRoot);
            return;
        }

        var runner = createRunner();
        var halArgs:Array<Value> = [];
        for (i in 1...args.length) halArgs.push(VString(args[i]));

        try {
            var res = runner.run(args[0], halArgs);
            switch (res) {
                case VNumber(n): Sys.exit(Std.int(n));
                default: Sys.exit(0);
            }
        } catch (e:Dynamic) {
            Sys.stderr().writeString(Std.string(e) + "\n");
            Sys.exit(1);
        }
    }

    static function createRunner():Runner {
        var runner = new DemoRunner();

        // 1. Register StdLib (Optional)
        var std = StdLib.getModules();
        for (name => tasks in std) {
            runner.registerModule(name, tasks);
        }

        return runner;
    }

    static function runConformance(workspaceRoot:String) {
        var tests = [
            "test/conformance/01_literals.hal",
            "test/conformance/02_gates.hal",
            "test/conformance/03_scoping.hal",
            "test/conformance/04_hoisting.hal",
            "test/conformance/05_params.hal",
            "test/conformance/06_macros.hal",
            "test/conformance/07_returns.hal",
            "test/conformance/08_host_args.hal",
            "test/conformance/09_deep_nesting.hal",
            "test/conformance/10_edge_cases.hal",
            "test/conformance/11_regex_parse.hal",
            "test/conformance/12_data_advanced.hal",
            "test/conformance/13_logic_module.hal",
            "test/conformance/14_syslib_hank.hal",
        ];

        for (t in tests) {
            Sys.println('--- Running: $t ---');
            var runner = createRunner();
            var path = Path.join([workspaceRoot, t]);
            var args:Array<Value> = [];
            if (StringTools.endsWith(t, "08_host_args.hal")) {
                args.push(VString("Tamas"));
            }
            try {
                runner.run(path, args);
            } catch (e:Dynamic) {
                Sys.println('Test Failed: $e');
            }
            Sys.println('--------------------\n');
        }
    }
}
