package localize.provider;

using tink.CoreApi;

interface StringReader {
	function read(language:String):Promise<String>;
}