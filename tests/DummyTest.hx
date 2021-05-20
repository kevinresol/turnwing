package;

import turnwing.*;
import tink.unit.Assert.*;
import Locales;

using tink.CoreApi;

@:asserts
class DummyTest {
	public function new() {}

	public function localize() {
		final locale = new Dummy<MyLocale>();
		asserts.assert(locale.empty() == '<empty>');
		asserts.assert(locale.hello('World') == '<hello name:World>');
		asserts.assert(locale.bool(true) == '<bool value:true>');
		asserts.assert(locale.bool(false) == '<bool value:false>');
		return asserts.done();
	}

	public function child() {
		final loc = new Dummy<ParentLocale>();
		
		function test(loc:MyLocale) {
			asserts.assert(loc.empty() == '<empty>');
			asserts.assert(loc.hello('World') == '<hello name:World>');
			asserts.assert(loc.bool(true) == '<bool value:true>');
			asserts.assert(loc.bool(false) == '<bool value:false>');
		}
		test(loc.normal);
		test(loc.getter);
		test(loc.const);
		return asserts.done();
	}

	// public function extended() {
	// 	final source = new ResourceStringSource(lang -> 'extended-$lang.json');
	// 	final loc = new Manager<ExtendedLocale>(new JsonProvider<ExtendedLocale>(source, template));
	// 	return loc.get('en').next(locale -> {
	// 		asserts.assert(locale.extended() == 'Extension!');
	// 		asserts.assert(locale.empty() == 'Hello, World!');
	// 		asserts.assert(locale.hello('World') == 'Hello, World!');
	// 		asserts.assert(locale.bool(true) == 'Yes');
	// 		asserts.assert(locale.bool(false) == 'No');
	// 		asserts.done();
	// 	});
	// }
}
