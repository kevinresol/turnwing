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
	final source:Source<String> = new ResourceStringSource(lang -> '$lang.ftl');

	public function new() {}

	public function localize() {
		final loc = new Manager<MyLocale>(new FluentProvider<MyLocale>(source, {useIsolating: false}));
		return loc.get('en').next(locale -> {
			asserts.assert(locale.empty() == 'Hello, World!');
			asserts.assert(locale.hello('World') == 'Hello, World!');
			asserts.assert(locale.bool(true) == 'Yes');
			asserts.assert(locale.bool(false) == 'No');
			asserts.done();
		});
	}

	public function noData() {
		final loc = new Manager<MyLocale>(new FluentProvider<MyLocale>(source, {useIsolating: false}));
		return loc.get('dummy').map(o -> assert(!o.isSuccess()));
	}

	public function invalid() {
		final loc = new Manager<InvalidLocale>(new FluentProvider<InvalidLocale>(source, {useIsolating: false}));
		return loc.get('en').map(o -> assert(!o.isSuccess()));
	}

	public function child() {
		final source = new ResourceStringSource(lang -> 'child-$lang.ftl');
		final loc = new Manager<ParentLocale>(new FluentProvider<ParentLocale>(source, {useIsolating: false}));
		return loc.get('en').next(en -> {
			function test(loc:MyLocale) {
				asserts.assert(loc.empty() == 'Hello, World!');
				asserts.assert(loc.hello('World') == 'Hello, World!');
				asserts.assert(loc.bool(true) == 'Yes');
				asserts.assert(loc.bool(false) == 'No');
			}
			test(en.normal);
			test(en.getter);
			test(en.const);
			asserts.done();
		});
	}
}
