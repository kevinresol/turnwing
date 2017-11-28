package turnwing.provider;

#if !macro

import turnwing.*;
using tink.CoreApi;

@:genericBuild(turnwing.provider.JsonProvider.build())
class JsonProvider<T> {}

@:require(tink_json, 'Missing dependency: tink_json')
class JsonProviderBase<T> implements Provider<T> {
	var reader:StringReader;
	
	public function new(reader)
		this.reader = reader;
	
	public function fetch(language:Language):Promise<T>
		throw 'abstract';
}

#else

import tink.macro.BuildCache;
using tink.MacroApi;

class JsonProvider {
	public static function build() {
		return BuildCache.getType('turnwing.provider.JsonProvider', function(ctx:BuildContext) {
			var name = ctx.name;
			var ct = ctx.type.toComplex();
			
			var def = macro class $name extends turnwing.provider.JsonProvider.JsonProviderBase<$ct> {
				override function fetch(language:String):tink.core.Promise<$ct>
					return reader.read(language).next(function(raw) return tink.Json.parse((raw:$ct)));
			}
			
			def.pack = ['turnwing'];
			return def;
		});
	}
}
#end