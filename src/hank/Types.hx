package hank;

enum ValueType {
    TypeVoid;
    TypeNumber;
    TypeString;
    TypeArray;
    TypeMap;
    TypeOpaque;
    TypeTask;
    TypeError;
}

enum Value {
    VVoid;
    VNumber(v:Float);
    VString(v:String);
    VArray(v:Array<Value>);
    VMap(v:Map<String, Value>);
    VOpaque(label:String, data:Dynamic);
    VTask(v:TaskValue);
    VError(code:Int, args:Array<Value>);
}

typedef TaskValue = {
    var isNative:Bool;
    var name:String;
    @:optional var params:Array<Param>;
    @:optional var body:Expr;
    @:optional var closure:Scope;
    @:optional var native:Array<Value>->ExecutionContext->Value;
}

typedef Param = {
    var name:String;
    var isOptional:Bool;
    @:optional var defaultValue:Expr;
}

interface ExecutionContext {
    function call(task:Value, args:Array<Value>):Value;
    function eval(node:Expr):Value;
    function isError(val:Value):Bool;
    function getLocalization():Map<Int, String>;
    var scope(get, never):Scope;
}

interface Scope {
    function get(name:String):Value;
    function set(name:String, val:Value):Void;
    function exists(name:String):Bool;
}

typedef TokenData = {
    var line:Int;
    var column:Int;
    var lineText:String;
}

enum Expr {
    EBlock(stmts:Array<Expr>, td:TokenData);
    EAssign(name:String, value:Expr, td:TokenData);
    ELiteral(value:Value, td:TokenData);
    EIdent(name:String, isCore:Bool, td:TokenData);
    EFuncDef(params:Array<Param>, body:Expr, td:TokenData);
    EFuncCall(target:Expr, args:Array<Expr>, td:TokenData);
    EUnOp(op:String, target:Expr, td:TokenData);
    EMap(fields:Map<String, Expr>, td:TokenData);
    EArray(items:Array<Expr>, td:TokenData);
    EFlowControl(condition:Expr, success:Expr, ?fallback:Expr, ?rescue:Expr, ?catchVar:String, td:TokenData);
    EError(code:Int, args:Array<Expr>, td:TokenData);
}

interface IHankSerializable {
    function serializeHank():String;
}

class ValueTools {
    public static function getType(v:Value):ValueType {
        return switch (v) {
            case VVoid: TypeVoid;
            case VNumber(_): TypeNumber;
            case VString(_): TypeString;
            case VArray(_): TypeArray;
            case VMap(_): TypeMap;
            case VOpaque(_, _): TypeOpaque;
            case VTask(_): TypeTask;
            case VError(_, _): TypeError;
        }
    }

    public static function typeToString(t:ValueType):String {
        return switch (t) {
            case TypeVoid: "Void";
            case TypeNumber: "Number";
            case TypeString: "String";
            case TypeArray: "Array";
            case TypeMap: "Map";
            case TypeOpaque: "Opaque";
            case TypeTask: "Task";
            case TypeError: "Error";
        }
    }

    public static function toString(v:Value):String {
        return switch (v) {
            case VVoid: "Void";
            case VNumber(n): 
                var s = Std.string(n);
                if (StringTools.endsWith(s, ".0")) s = s.substring(0, s.length - 2);
                s;
            case VString(s): s;
            case VArray(_): "[Array]";
            case VMap(_): "[Map]";
            case VOpaque(label, _): '[Opaque:$label]';
            case VTask(_): "[Task]";
            case VError(code, _): '[Error:$code]';
        }
    }
}

class ExprTools {
    public static function getTd(e:Expr):TokenData {
        return switch (e) {
            case EBlock(_, td) | EAssign(_, _, td) | ELiteral(_, td) | EIdent(_, _, td) | EFuncDef(_, _, td) | EFuncCall(_, _, td) | EUnOp(_, _, td) | EMap(_, td) | EArray(_, td) | EFlowControl(_, _, _, _, _, td) | EError(_, _, td): td;
        }
    }
}

enum abstract HankError(Int) to Int from Int {
    // Lexical Errors (10xx)
    var UnexpectedCharacter = 1001;
    var UnclosedStringLiteral = 1002;

    // Syntax Errors (20xx)
    var EmptyScript = 2001;
    var ExpectedMainTask = 2002;
    var UnexpectedCodeOutsideMainTask = 2003;
    var InvalidAssignmentTarget = 2004;
    var UnexpectedToken = 2005;
    var MacroRequiresString = 2006;
    var ExpectedIdentifier = 2007;

    // Resolution & Runner Errors (30xx)
    var CircularDependency = 3001;
    var ResourceContentNotLoaded = 3002;
    var ScriptMustBeTask = 3003;
    var MacroResourceNotFound = 3004;

    // Runtime Errors (40xx)
    var TargetNotFunction = 4001;
    var TooManyArguments = 4002;
    var MissingRequiredParameter = 4003;
    var Halt = 4004;
    var BitwiseOutOfBounds = 4005;
    var GenericRuntimeError = 4006;
    var TypeMismatch = 4007;
    var InstructionLimitExceeded = 4008;
}

class HankErrorValue {
    public var code:HankError;
    public var message:String;
    public var fileName:String;
    public var line:Int;
    public var column:Int;
    public var lineText:String;

    public function new(code:HankError, message:String, ?fileName:String, ?line:Int, ?column:Int, ?lineText:String) {
        this.code = code;
        this.message = message;
        this.fileName = fileName;
        this.line = line == null ? 0 : line;
        this.column = column == null ? 0 : column;
        this.lineText = lineText;
    }

    public function toString():String {
        return message;
    }
}

class HankErrorRegistry {
    public static var messages:Map<HankError, String> = [
        UnexpectedCharacter => "Unexpected character: {0}",
        UnclosedStringLiteral => "Unclosed string literal",

        EmptyScript => "Syntax Error: Script is empty.",
        ExpectedMainTask => "Syntax Error: Expected main task definition (a closure or a block).",
        UnexpectedCodeOutsideMainTask => "Syntax Error: Unexpected code outside of main task. A Hank script must contain exactly one Task definition.",
        InvalidAssignmentTarget => "Invalid assignment target",
        UnexpectedToken => "Unexpected token: {0} ({1})",
        MacroRequiresString => "Syntax Error: The '@' macro strictly requires a string literal path (e.g., @ \"utils\"). Identifier shorthand is not allowed.",
        ExpectedIdentifier => "Expected identifier, found {0}",

        CircularDependency => "Circular Dependency: {0}",
        ResourceContentNotLoaded => "Resource content not loaded: {0}",
        ScriptMustBeTask => "Hank Error: Script must evaluate to a Task definition.",
        MacroResourceNotFound => "Macro resource not found: @{0}",

        TargetNotFunction => "Target is not a function: {0}",
        TooManyArguments => "Too many arguments",
        MissingRequiredParameter => "Missing required parameter: {0}",
        Halt => "HANK_HALT:{0}",
        BitwiseOutOfBounds => "Value exceeds safe integer bounds for bitwise operation: {0}",
        TypeMismatch => "Type Mismatch: Expected {0}, got {1} in {2}",
        InstructionLimitExceeded => "Instruction Limit Exceeded: Script reached the maximum allowed AST evaluations ({0})",
        GenericRuntimeError => "{0}"
    ];

    public static function create(code:HankError, ?args:Array<Dynamic>, ?fileName:String, ?line:Int, ?column:Int, ?lineText:String):HankErrorValue {
        var tmpl = messages.get(code);
        if (tmpl == null) tmpl = "Unknown Error";

        if (args != null) {
            for (i in 0...args.length) {
                tmpl = StringTools.replace(tmpl, '{' + i + '}', Std.string(args[i]));
            }
        }

        var fullMessage = tmpl;
        if (fileName != null && line != null && lineText != null) {
            fullMessage = 'ERROR: $tmpl in $fileName at\n\t$line:\t$lineText';
        }

        return new HankErrorValue(code, fullMessage, fileName, line, column, lineText);
    }
}
