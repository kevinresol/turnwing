package;

import turnwing.*;
import turnwing.provider.*;
import turnwing.template.*;
import tink.unit.Assert.*;

using tink.CoreApi;

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
class JsonTest {
	var reader:StringReader;
	var template:Template;
	
	public function new() {}
	
	@:before
	public function before() {
		reader = new ResourceReader(function(lang) return '$lang.json');
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
		var reader = new ResourceReader(function(lang) return 'child-$lang.json');
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