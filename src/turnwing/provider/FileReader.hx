package turnwing.provider;

using haxe.io.Path;
using sys.FileSystem;
using sys.io.File;
using tink.CoreApi;

class FileReader implements StringReader {
	
	var getFilename:String->String;
	
	public function new(?getFilename:String->String) {
		this.getFilename = getFilename != null ? getFilename : function(lang) return '$lang.json';
	}
		
	public function read(language:String):Promise<String>
		return Error.catchExceptions(function() return getFilename(language).getContent());
}

