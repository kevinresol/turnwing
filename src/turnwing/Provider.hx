package turnwing;

using tink.CoreApi;

interface Provider<T> {
	function fetch(language:Language):Promise<T>;
}

