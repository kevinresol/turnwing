package turnwing.source;

class CachedSource<T> implements Source<T> {
	final getKey:String->String;
	final source:Source<T>;
	final cache:Map<String, Promise<T>>;

	public function new(getKey, source, ?cache) {
		this.getKey = getKey;
		this.source = source;
		this.cache = cache == null ? [] : cache;
	}

	public function fetch(language:String):Promise<T> {
		final key = getKey(language);
		return switch cache[key] {
			case null: cache[key] = source.fetch(language);
			case v: v;
		}
	}
}
