package turnwing.source;

import turnwing.source.Source;

class ResourceStringSource implements Source<String> {
	final getResourceName:(lang:String) -> String;

	public function new(getResourceName)
		this.getResourceName = getResourceName;

	public function fetch(language:String):Promise<String> {
		final name = getResourceName(language);
		return Error.catchExceptions(() -> switch haxe.Resource.getString(name) {
			case null: throw new Error(NotFound, 'No resource named "$name"');
			case v: v;
		});
	}
}
