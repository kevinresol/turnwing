package turnwing.provider;

interface Provider<Locale> {
	function prepare(language:String):Promise<Locale>;
}
