# Hackable localization library for Haxe

**Goals:**

- Type safe
- Hackable (plug in different implementations at various part of the library)

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