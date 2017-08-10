package;

import turnwing.*;
import turnwing.provider.*;
import turnwing.template.*;
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

interface InvalidLocale {
	function foo(name:String):String;
}

class LocalizerTest {
	var reader:StringReader;
	var template:Template;
	
	public function new() {}
	
	@:before
	public function before() {
		reader = new FileReader(function(lang) return './tests/data/$lang.json');
		template = new HaxeTemplate();
		return Noise;
	}
	
	public function localize() {
		var loc = new Manager<MyLocale>(new JsonProvider(reader), template);
		return loc.prepare(['en'])
			.next(function(o) return assert(loc.language('en').hello('World') == 'Hello, World!'));
	}
	
	public function noData() {
		var loc = new Manager<MyLocale>(new JsonProvider(reader), template);
		return loc.prepare(['dummy'])
			.map(function(o) return assert(!o.isSuccess()));
	}
	
	public function invalid() {
		var loc = new Manager<InvalidLocale>(new JsonProvider(reader), template);
		return loc.prepare(['en'])
			.map(function(o) return assert(!o.isSuccess()));
	}
}