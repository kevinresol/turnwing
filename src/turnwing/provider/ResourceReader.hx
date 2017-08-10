package turnwing.provider;

using tink.CoreApi;

class ResourceReader implements StringReader {
	var getResourceName:String->String;
	
	public function new(?getResourceName:String->String) {
		this.getResourceName = getResourceName != null ? getResourceName : function(lang) return lang;
	}
		
	public function read(language:String):Promise<String>
		return Error.catchExceptions(function() return haxe.Resource.getString(getResourceName(language)));
}

