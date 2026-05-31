package hank;

import hank.Types;

interface IExtension {
    public var name(default, null):String;
    public function getTasks():Map<String, Array<Value>->ExecutionContext->Value>;
}
