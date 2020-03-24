package turnwing.util;

abstract Prefix(String) to String {
	public inline function new()
		this = '';

	public inline function add(name:String, delimiter = ''):Prefix
		return cast(this == '' ? name : this + delimiter + name);
}
