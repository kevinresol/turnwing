package turnwing;

import turnwing.provider.Provider;

class Manager<Locale> {
	final provider:Provider<Locale>;
	final locales:Map<String, Locale>;

	public function new(provider) {
		this.provider = provider;
		this.locales = new Map();
	}

	public function prepare(languages:Array<String>, forceRefresh = false):Promise<Noise> {
		var tasks = [];

		for (language in languages)
			if (forceRefresh || !locales.exists(language))
				tasks.push(provider.prepare(language).next(locale -> {
					locales.set(language, locale);
					Noise;
				}));

		return Promise.inParallel(tasks);
	}

	public function language(language:String):Locale {
		return switch locales.get(language) {
			case null: throw '"$language" is not ready, call `prepare()` first';
			case v: v;
		}
	}
}
