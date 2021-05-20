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
}
