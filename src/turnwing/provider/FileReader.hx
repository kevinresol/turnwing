package turnwing.provider;

import turnwing.provider.StringReader;

using haxe.io.Path;
using sys.FileSystem;
using sys.io.File;
using tink.CoreApi;

class FileReader implements StringReaderObject {
	
	var getFilename:Language->String;
	
	public function new(?getFilename:Language->String)
		this.getFilename = getFilename != null ? getFilename : function(lang) return '$lang.json';
		
	public function read(language:Language):Promise<String>
		return Error.catchExceptions(function() return getFilename(language).getContent());
}

