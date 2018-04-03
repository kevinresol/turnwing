package turnwing.provider;

import turnwing.provider.StringReader;

using tink.CoreApi;

class ResourceReader implements StringReaderObject {
	
	public function new(?getResourceName:Language->String)
		if(getResourceName != null) this.getResourceName = getResourceName;
		
	public dynamic function getResourceName(lang:Language):String
		return lang;
	
	public function read(language:Language):Promise<String>
		return Error.catchExceptions(function() return haxe.Resource.getString(getResourceName(language)));
}

