package;

import turnwing.*;
import turnwing.provider.*;
import turnwing.source.*;
import turnwing.template.*;
import tink.unit.Assert.*;
import Locales;

using tink.CoreApi;

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
		return loc.get('en').next(function(locale) {
			asserts.assert(locale.empty() == 'Hello, World!');
			asserts.assert(locale.hello('World') == 'Hello, World!');
			asserts.assert(locale.bool(true) == 'Yes');
			asserts.assert(locale.bool(false) == 'No');
			return asserts.done();
		});
	}

	public function noData() {
		var loc = new Manager<MyLocale>(new FluentProvider<MyLocale>(source, {useIsolating: false}));
		return loc.get('dummy').map(function(o) return assert(!o.isSuccess()));
	}

	public function invalid() {
		var loc = new Manager<InvalidLocale>(new FluentProvider<InvalidLocale>(source, {useIsolating: false}));
		return loc.get('en').map(function(o) return assert(!o.isSuccess()));
	}

	public function child() {
		var source = new ResourceStringSource(lang -> 'child-$lang.ftl');
		var loc = new Manager<ParentLocale>(new FluentProvider<ParentLocale>(source, {useIsolating: false}));
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
