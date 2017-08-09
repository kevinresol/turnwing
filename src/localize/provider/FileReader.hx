package localize.provider;

using haxe.io.Path;
using sys.FileSystem;
using sys.io.File;
using tink.CoreApi;

class FileReader implements StringReader {
	var folder:String;
	
	public function new(folder:String)
		this.folder = folder.absolutePath();
		
	public function read(language:String):Promise<String>
		return Error.catchExceptions(function() return '$folder/$language.json'.getContent());
}

