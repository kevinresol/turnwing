package turnwing.provider;

import turnwing.provider.StringReader;

using haxe.io.Path;
using sys.FileSystem;
using sys.io.File;
using tink.CoreApi;

class FileReader implements StringReaderObject {
	
	public function new(?getFilename:Language->String)
		if(getFilename != null) this.getFilename = getFilename;
	
	public dynamic function getFilename(lang:Language):String
		 return '$lang.json';
		
	public function read(language:Language):Promise<String>
		return Error.catchExceptions(function() return getFilename(language).getContent());
}

