package turnwing.source;

import turnwing.source.Source;

class WebStringSource implements Source<String> {
	final getUrl:(lang:String) -> String;

	public function new(getUrl)
		this.getUrl = getUrl;

	public function fetch(language:String):Promise<String>
		return tink.http.Fetch.fetch(getUrl(language)).all().next(res -> res.body.toString());
}
