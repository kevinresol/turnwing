package turnwing.source;

import turnwing.source.Source;

class ResourceStringSource implements Source<String> {
	public function new(?getResourceName:String->String)
		if (getResourceName != null)
			this.getResourceName = getResourceName;

	dynamic function getResourceName(lang:String):String
		return lang;

	public function fetch(language:String):Promise<String> {
		var name = getResourceName(language);
		return Error.catchExceptions(function() return switch haxe.Resource.getString(name) {
			case null: throw new Error(NotFound, 'No resource named "$name"');
			case v: v;
		});
	}
}
