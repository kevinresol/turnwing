package turnwing;

import turnwing.*;
using tink.CoreApi;

@:genericBuild(turnwing.Macro.buildManager())
class Manager<Locale> {}

class ManagerBase<Locale, Data> {
	
	var provider:Provider<Data>;
	var template:Template;
	var locales:Map<Language, Locale>;
	var data:Map<Language, Data>;
	
	
	public function new(provider, template) {
		this.provider = provider;
		this.template = template;
		locales = new Map();
		data = new Map();
	}
	
	public function prepare(languages:Array<Language>, forceRefresh = false):Promise<Noise> {
		if(forceRefresh) {
			locales = new Map();
			data = new Map();
		}
		
		var promises = [];
		for(language in languages)
			if(!data.exists(language))
				promises.push(provider.fetch(language).next(function(d) {
					data[language] = d;
					return Noise;
				}));
				
		return Promise.inParallel(promises);
	}
	
	public function language(language:Language):Locale {
		if(!data.exists(language))
			throw 'Localization data for language "$language" is not ready. Call prepare() first.';
			
		if(!locales.exists(language))
			locales[language] = createLocale(data[language]);
		
		return locales[language];
	}
	
	function createLocale(data:Data):Locale {
		throw 'abstract';
		// return new Localizer<Locale>(data); // this is macro-built
	}
}
