package;

import turnwing.*;
import turnwing.provider.*;
import turnwing.source.*;
import turnwing.template.*;
import tink.unit.Assert.*;

using tink.CoreApi;

interface MyLocale {
	function empty():String;
	function hello(name:String):String;
}

interface InvalidLocale { // test invalid source
	function foo(name:String):String;
}

// interface ParentLocale {
// 	var normal(default, null):MyLocale;
// 	var getter(get, null):MyLocale;
// 	final ultimate:MyLocale;
// }

@:asserts
class FluentTest {
	var source:Source<String>;

	public function new() {}

	@:before
	public function before() {
		source = new ResourceStringSource(lang -> '$lang.ftl');
		return Noise;
	}

	public function localize() {
		var loc = new Manager<MyLocale>(new FluentProvider<MyLocale>(source, {useIsolating: false}));
		return loc.prepare(['en']).next(function(o) {
			asserts.assert(loc.language('en').empty() == 'Hello, World!');
			asserts.assert(loc.language('en').hello('World') == 'Hello, World!');
			return asserts.done();
		});
	}

	public function noData() {
		var loc = new Manager<MyLocale>(new FluentProvider<MyLocale>(source, {useIsolating: false}));
		return loc.prepare(['dummy']).map(function(o) return assert(!o.isSuccess()));
	}

	public function invalid() {
		var loc = new Manager<InvalidLocale>(new FluentProvider<InvalidLocale>(source, {useIsolating: false}));
		return loc.prepare(['en']).map(function(o) return assert(!o.isSuccess()));
	}

	// public function child() {
	// 	var source = new ResourceStringSource(lang -> 'child-$lang.ftl');
	// 	var loc = new Manager<ParentLocale>(new FluentProvider<ParentLocale>(source, {useIsolating: false}));
	// 	return loc.prepare(['en']).next(function(o) {
	// 		var en = loc.language('en');
	// 		function test(loc:MyLocale) {
	// 			asserts.assert(loc.empty() == 'Hello, World!');
	// 			asserts.assert(loc.hello('World') == 'Hello, World!');
	// 		}
	// 		test(en.normal);
	// 		test(en.getter);
	// 		test(en.ultimate);
	// 		return asserts.done();
	// 	});
	// }
}
