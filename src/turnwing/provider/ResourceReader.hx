package turnwing.provider;

import turnwing.provider.StringReader;

using tink.CoreApi;

class ResourceReader implements StringReaderObject {
	var getResourceName:Language->String;
	
	public function new(?getResourceName:Language->String)
		this.getResourceName = getResourceName != null ? getResourceName : function(lang) return lang;
		
	public function read(language:Language):Promise<String>
		return Error.catchExceptions(function() return haxe.Resource.getString(getResourceName(language)));
}

