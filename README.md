# turnwing

Hackable localization library for Haxe

## What?

### Type safety

Translation are done with interfaces. You will never mis-spell the translation key anymore.

```haxe
// no more string keys and dynamic parameters:
loc.translate('hello', {name: 'World'});

// use function calls with typed parameters instead
loc.hello('World');
```

### Piece of mind

Data are validated when they are loaded. Combining with type-safety, you can be sure that the translation calls will not fail.

For example, if our `Locale` contains a translation function named `hello`.
Then the `Provider` will ensure there is a localization string named `hello` when the data is loaded at runtime, not when the data is used (i.e. when `hello()` is called). This allow the program to fail gracefully and early.

### Hackable

Users can plug in different implementations at various part of the library. May it be a `XmlProvider` that parses XML into localization data, or a `ErazorTemplate` that uses another templating engine under the hood.

## Usage

```haxe
import localize.*;

interface MyLocale {
	function hello(name:String):String;
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
				trace(localizer.hello('World'));
			case Failure(e):
				// something went wrong when fetching the localization data
				trace(e);
		});
	}
}
```

## Providers

`JsonProvider` is a validating data provider with JSON sources. It utilizes `tink_json` to validate json strings at runtime. Giving you the chance to gracefully fail when the JSON source is invalid.

```haxe
var reader = new FileReader('./data');
var provider = new JsonProvider<Data<MyLocale>>(reader);
```

## Templates

`HaxeTemplate` is based on the one provided by Haxe's standard library (`haxe.Template`)