package localize.template;

import localize.*;

class HaxeTemplate implements Template {
	public function new() {}
	public function execute(raw:String, params:Dynamic):String
		return new haxe.Template(raw).execute(params);
}