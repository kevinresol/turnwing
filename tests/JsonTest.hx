package;

import turnwing.*;
import turnwing.provider.*;
import turnwing.source.*;
import turnwing.template.*;
import tink.unit.Assert.*;
import Locales;

using tink.CoreApi;

@:asserts
class JsonTest {
	var source:Source<String>;
	var template:Template;

	public function new() {}

	@:before
	public function before() {
		source = new ResourceStringSource(lang -> '$lang.json');
		template = new HaxeTemplate();
		return Noise;
	}

	public function localize() {
		var loc = new Manager<MyLocale>(new JsonProvider<MyLocale>(source, template));
		return loc.get('en').next(function(locale) {
			asserts.assert(locale.empty() == 'Hello, World!');
			asserts.assert(locale.hello('World') == 'Hello, World!');
			asserts.assert(locale.bool(true) == 'Yes');
			asserts.assert(locale.bool(false) == 'No');
			return asserts.done();
		});
	}

	public function noData() {
		var loc = new Manager<MyLocale>(new JsonProvider<MyLocale>(source, template));
		return loc.get('dummy').map(function(o) return assert(!o.isSuccess()));
	}

	public function invalid() {
		var loc = new Manager<InvalidLocale>(new JsonProvider<InvalidLocale>(source, template));
		return loc.get('en').map(function(o) return assert(!o.isSuccess()));
	}

	public function child() {
		var source = new ResourceStringSource(lang -> 'child-$lang.json');
		var loc = new Manager<ParentLocale>(new JsonProvider<ParentLocale>(source, template));
		return loc.get('en').next(function(en) {
			function test(loc:MyLocale) {
				asserts.assert(loc.empty() == 'Hello, World!');
				asserts.assert(loc.hello('World') == 'Hello, World!');
				asserts.assert(loc.bool(true) == 'Yes');
				asserts.assert(loc.bool(false) == 'No');
			}
			test(en.normal);
			test(en.getter);
			test(en.ultimate);
			return asserts.done();
		});
	}
}
