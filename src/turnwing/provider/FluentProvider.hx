package turnwing.provider;

import turnwing.source.Source;
import turnwing.util.Prefix;

@:genericBuild(turnwing.provider.FluentProvider.build())
class FluentProvider<Locale> {}

@:genericBuild(turnwing.provider.FluentProvider.FluentLocale.build())
class FluentLocale<Locale> {}

class FluentProviderBase<Locale> implements Provider<Locale> {
	final source:Source<String>;
	final opt:{?useIsolating: Bool};

	public function new(source, ?opt) {
		this.source = source;
		this.opt = opt;
	}

	public function prepare(language:String):Promise<Locale>
		return source.fetch(language).next(bundle.bind(language)).next(make);

	function bundle(language:String, ftl:String):Outcome<FluentBundle, Error> {
		return if (ftl == null) {
			Failure(new Error('Empty ftl data'));
		} else {
			var resource = new FluentResource(ftl);
			var bundle = new FluentBundle(language, opt);
			bundle.addResource(resource);
			validate(bundle);
		}
	}

	function validate(bundle:FluentBundle):Outcome<FluentBundle, Error>
		throw 'abstract';

	function make(bundle:FluentBundle):Locale
		throw 'abstract';
}

class FluentLocaleBase {
	final __bundle__:FluentBundle;
	final __prefix__:Prefix;

	public function new(bundle, prefix) {
		__bundle__ = bundle;
		__prefix__ = prefix;
	}
}

@:jsRequire('@fluent/bundle', 'FluentBundle')
extern class FluentBundle {
	function new(lang:String, ?opts:{});
	function addResource(res:FluentResource):Array<js.lib.Error>;
	function getMessage(id:String):FluentMessage;
	function formatPattern(pattern:FluentPattern, params:Dynamic):String;
}

@:jsRequire('@fluent/bundle', 'FluentResource')
extern class FluentResource {
	function new(ftl:String);
}

typedef FluentMessage = {
	id:String,
	value:FluentPattern,
}

typedef FluentPattern = haxe.extern.EitherType<String, Array<FluentPatternElement>>;
typedef FluentPatternElement = Any;
/*
	class FluentProviderImpl {
	function parse(v:String):Outcome<FluentResource, Error>
		throw 'abstract';
	}

	class FluentLocaleImpl {
	public function new()
		public function foo(name:String) {
			return bundle.getMessage('foo', name)
		}
	}
 */
