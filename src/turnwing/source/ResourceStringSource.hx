package turnwing.source;

import turnwing.source.Source;

class ResourceStringSource implements Source<String> {
	public function new(?getResourceName:String->String)
		if (getResourceName != null)
			this.getResourceName = getResourceName;

	dynamic function getResourceName(lang:String):String
		return lang;

	public function fetch(language:String):Promise<String>
		return Error.catchExceptions(function() return haxe.Resource.getString(getResourceName(language)));
}
