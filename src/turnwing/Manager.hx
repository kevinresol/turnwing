package turnwing;

import turnwing.provider.Provider;

class Manager<Locale> {
	final provider:Provider<Locale>;
	final locales:Map<String, Locale>;

	public function new(provider) {
		this.provider = provider;
		this.locales = new Map();
	}

	public function get(language:String, forceRefresh = false):Promise<Locale> {
		// @formatter:off
		return 
			if (forceRefresh || !locales.exists(language))
				provider.prepare(language).next(locale -> {
					locales.set(language, locale);
					locale;
				});
			else
				Promise.resolve(locales.get(language));
		// @formatter:on
	}
}
