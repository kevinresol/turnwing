package localize.provider;

import haxe.Json;
import localize.*;
using tink.CoreApi;

@:genericBuild(localize.Macro.buildJsonProvider())
class JsonProvider<T> {}

class JsonProviderBase<T> implements Provider<T> {
	var reader:StringReader;
	
	public function new(reader)
		this.reader = reader;
	
	public function fetch(language:String):Promise<T> {
		throw 'abstract';
	}
}
