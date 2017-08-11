# turnwing

Hackable localization library for Haxe

## What?

### Type safety

Translation are done with interfaces. You will never mis-spell the translation key anymore.

```haxe
// no more old style translator: 
// there is one and only one translation function and its type is String->Dynamic->String
// serveral things can go wrong here: wrong translation key, wrong param name, wrong param data type
loc.translate('hello', {name: 'World'}); 
loc.translate('orange', {number: 1});


// with turnwing, we have typed translators: 
// there are a number of user-defined functions and each one is typed specifically
loc.hello('World'); // String->String
loc.orange(1); // Int->String
```

### Piece of mind

There is only one place where errors could happen, that is when the localization data is loaded.

This is because data are validated when they are loaded. The data provider does all the heavy lifting to make sure the loaded data includes all the needed translation keys and values. As a result, there is no chance for actual translation calls to fail.

### Hackable

Users can plug in different implementations at various part of the library. May it be a `XmlProvider` that parses XML into localization data, or a `ErazorTemplate` that uses the erazor templating engine to render the result.

## Usage

```haxe
import localize.*;

interface MyLocale {
	function hello(name:String):String;
	function orange(number:Int):String;
}

class Main {
	static function main() {
		var provider = /* choose one from localize.provider package or implements your own Provider */;
		var template = /* choose one from localize.template package or implements your own Template */;
		var loc = new Manager<MyLocale>(provider, template);
		loc.prepare(['en']).handle(function(o) switch o {
			case Success(_):
				// data prepared, we can now translate something
				var localizer = loc.language('en'); 
				$type(localizer); // MyLocale
				trace(localizer.hello('World')); // "Hello, World!"
				trace(localizer.orange(4)); // "There are 4 orange(s)!"
			case Failure(e):
				// something went wrong when fetching the localization data
				trace(e);
		});
	}
}

// and your json data looks like this:
{
	"hello": "Hello, ::name::",
	"orange": "There are ::number:: orange(s)!"
}
```

## Providers

`JsonProvider` is a data provider for JSON sources. Its data validation is powered by `tink_json`, which generates the validation code with macro at compile time, according the type information of the user-defined locale interface.

```haxe
var reader = new FileReader(function(lang) return './data/$lang.json');
var provider = new JsonProvider<Data<MyLocale>>(reader);
```

To use it, install `tink_json` and include it as dependency in your project

## Templates

`HaxeTemplate` is based on the one provided by Haxe's standard library (`haxe.Template`)
