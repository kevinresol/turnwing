package turnwing.provider;

import haxe.Json;
import turnwing.*;
using tink.CoreApi;

@:genericBuild(turnwing.Macro.buildJsonProvider())
class JsonProvider<T> {}

class JsonProviderBase<T> implements Provider<T> {
	var reader:StringReader;
	
	public function new(reader)
		this.reader = reader;
	
	public function fetch(language:String):Promise<T> {
		throw 'abstract';
	}
}
