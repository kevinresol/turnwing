package localize;

interface Template {
	function execute(raw:String, params:Dynamic):String;
}