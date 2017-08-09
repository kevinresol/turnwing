package;

import localize.*;
import localize.provider.*;
import localize.template.*;
import tink.unit.*;
import tink.unit.Assert.*;
import tink.testrunner.*;

using tink.CoreApi;

class RunTests {

	static function main() {
		Runner.run(TestBatch.make([
			new LocalizerTest()
		])).handle(Runner.exit);
	}
	
}

interface MyLocale {
	function hello(name:String):String;
}

class LocalizerTest {
	public function new() {};
	
	public function test() {
		var reader = new FileReader('./tests/data');
		var provider = new JsonProvider(reader);
		var template = new HaxeTemplate();
		var loc = new Manager<MyLocale>(provider, template);
		return loc.prepare(['en'])
			.next(function(o) return assert(loc.language('en').hello('World') == 'Hello, World!'));
	}
}