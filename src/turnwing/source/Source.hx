package turnwing.source;

interface Source<T> {
	function fetch(language:String):Promise<T>;
}
