package turnwing.provider;

import turnwing.source.Source;
import turnwing.template.Template;

/**
 * JsonProvider consumes the JSON syntax.
 * Each key corresponds to the function name of the Locale interface.
 * Nested interfaces are represented as nested objects.
 *
 * Example: (usage with HaxeTemplate)
 * ```json
 * {
 *   "plain": "plain value",
 *   "parametrized": "parameterized ::variableName::",
 *   "nested": {
 *     "another": "value"
 *   }
 * }
 * ```
 */
@:genericBuild(turnwing.provider.JsonProvider.build())
class JsonProvider<Locale> {}

@:genericBuild(turnwing.provider.JsonProvider.JsonLocale.build())
class JsonLocale<Locale> {}

@:genericBuild(turnwing.provider.JsonProvider.JsonData.build())
class JsonData<Locale> {}

class JsonProviderBase<Locale, Data> implements Provider<Locale> {
	final source:Source<String>;
	final template:Template;

	public function new(source, template) {
		this.source = source;
		this.template = template;
	}

	public function prepare(language:String):Promise<Locale>
		return source.fetch(language).next(parse).next(make);

	function parse(v:String):Outcome<Data, Error>
		throw 'abstract';

	function make(data:Data):Locale
		throw 'abstract';
}

class JsonLocaleBase<Data> {
	final __template__:Template;
	final __data__:Data;

	public function new(template, data) {
		__template__ = template;
		__data__ = data;
	}
}
