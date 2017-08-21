package turnwing.provider;

using tink.CoreApi;

@:forward
abstract StringReader(StringReaderObject) from StringReaderObject to StringReaderObject {
	
	public static inline function ofSyncFunction(f:String->String):StringReader
		return ofPromiseFunction(function(lang):Promise<String> return f(lang));
	
	public static inline function ofFutureFunction(f:String->Future<String>):StringReader
		return ofPromiseFunction(function(lang):Promise<String> return f(lang));
	
	public static inline function ofPromiseFunction(f:String->Promise<String>):StringReader
		return new SimpleStringReader(f);
		
}

class SimpleStringReader implements StringReaderObject {
	
	var f:String->Promise<String>;
	
	public function new(f)
		this.f = f;
		
	public function read(language:String):Promise<String>
		return f(language);
		
}

interface StringReaderObject {
	function read(language:String):Promise<String>;
}