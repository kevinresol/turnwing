package;

interface MyLocale {
	function empty():String;
	function hello(name:String):String;
	function bool(value:Bool):String;
}

interface InvalidLocale { // test invalid source
	function foo(name:String):String;
}

interface ParentLocale {
	var normal(default, null):MyLocale;
	var getter(get, null):MyLocale;
	final ultimate:MyLocale;
}

interface ExtendedLocale extends MyLocale {
	function extended():String;
}