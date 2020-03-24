# turnwing

Hackable localization library for Haxe

## What?

### Type safety

Translations are done with interfaces. You will never mis-spell the translation key anymore.

In many existing localization libraries, the translation function looks like this:

```haxe
loc.translate('hello', {name: 'World'});
loc.translate('orange', {number: 1});
```

There is one and only one translation function and its type is `String->Dynamic->String`.
That means it takes a String key, a Dynamic parameter object and returns a substituted string.
Several things can go wrong here: wrong translation key, wrong param name or wrong param data type.

With turnwing, we have typed translators.
Each of them is a user-defined function and typed specifically.

```haxe
loc.hello('World'); // String->String
loc.orange(1); // Int->String
```

### Peace of mind

There is only one place where errors could happen, that is when the localization data is loaded.

This is because data are validated when they are loaded. The data provider does all the heavy lifting to make sure the loaded data includes all the needed translation keys and values. As a result, there is no chance for actual translation calls to fail.

### Hackable

Users can plug in different implementations at various part of the library.

For example, `JsonProvider` uses JSON as the underlying localization format.
One can easily write a `XmlProvider` (perhaps with tink_xml).

Also, an `ErazorTemplate` may replace the default `HaxeTemplate` implementation.

## Usage

```haxe
import turnwing.*;
import turnwing.provider.*;
import turnwing.template.*;

interface MyLocale {
	function hello(name:String):String;
	function orange(number:Int):String;
	var sub(get, never):SubLocale;
}

interface SubLocale {
	function yo():String;
}

class Main {
	static function main() {
		var source = new ResourceStringSource(lang -> '$lang.json');
		var template = new HaxeTemplate();
		var loc = new Manager<MyLocale>(new JsonProvider<MyLocale>(source, template));
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
	"hello": "Hello, ::name::!",
	"orange": "There are ::number:: orange(s)!",
	"sub": {
		"yo": "Yo!"
	}
}
```

## Providers

`JsonProvider` is a data provider for JSON sources.
Its data validation is powered by `tink_json`,
which generates the validation code with macro at compile time
according to the type information of the user-defined locale interface.

Usage:

```haxe
var source = new ResourceStringSource(lang -> '$lang.json');
var template = new HaxeTemplate();
var provider = new JsonProvider<MyLocale>(source, template);
```

To use it, install `tink_json` and include it as dependency in your project
