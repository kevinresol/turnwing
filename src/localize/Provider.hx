package localize;

using tink.CoreApi;

interface Provider<T> {
	function fetch(language:String):Promise<T>;
}

