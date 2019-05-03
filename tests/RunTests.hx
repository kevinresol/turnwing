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
	var normal(default, null):String;
	var getter(get, null):String;
	#if haxe4
	final ultimate:String;
	#end
	
	function hello(name:String):String;
}

interface InvalidLocale {
	function foo(name:String):String;
}

interface ParentLocale {
	var normal(default, null):MyLocale;
	var getter(get, null):MyLocale;
	#if haxe4
	final ultimate:MyLocale;
	#end
}

@:asserts
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
			.next(function(o) {
				asserts.assert(loc.language('en').hello('World') == 'Hello, World!');
				asserts.assert(loc.language('en').normal == 'Hello, World!');
				asserts.assert(loc.language('en').getter == 'Hello, World!');
				#if haxe4
				asserts.assert(loc.language('en').ultimate == 'Hello, World!');
				#end
				return asserts.done();
			});
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
	
	public function child() {
		var reader = new FileReader(function(lang) return './tests/data/child-$lang.json');
		var loc = new Manager<ParentLocale>(new JsonProvider(reader), template);
		return loc.prepare(['en'])
			.next(function(o) {
				var en = loc.language('en');
				
				function test(loc:MyLocale) {
					asserts.assert(loc.hello('World') == 'Hello, World!');
					asserts.assert(loc.normal == 'Hello, World!');
					asserts.assert(loc.getter == 'Hello, World!');
					#if haxe4
					asserts.assert(loc.ultimate == 'Hello, World!');	
					#end
				}
				
				test(en.normal);
				test(en.getter);
				#if haxe4
				test(en.ultimate);
				#end
				
				return asserts.done();
			});
	}
}