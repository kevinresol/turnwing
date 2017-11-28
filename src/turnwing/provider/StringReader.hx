package turnwing.provider;

using tink.CoreApi;

@:forward
abstract StringReader(StringReaderObject) from StringReaderObject to StringReaderObject {
	
	public static inline function ofSyncFunction(f:Language->String):StringReader
		return ofPromiseFunction(function(lang):Promise<String> return f(lang));
	
	public static inline function ofFutureFunction(f:Language->Future<String>):StringReader
		return ofPromiseFunction(function(lang):Promise<String> return f(lang));
	
	public static inline function ofPromiseFunction(f:Language->Promise<String>):StringReader
		return new SimpleStringReader(f);
		
}

class SimpleStringReader implements StringReaderObject {
	
	var f:Language->Promise<String>;
	
	public function new(f)
		this.f = f;
		
	public function read(language:Language):Promise<String>
		return f(language);
		
}

interface StringReaderObject {
	function read(language:Language):Promise<String>;
}