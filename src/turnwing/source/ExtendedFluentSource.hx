package turnwing.source;

using haxe.io.Path;
using StringTools;

/**
 * A custom extension of the Fluent FTL format.
 * Supports a special "include" directive to import other .ftl files
 * 
 * Syntax: `# @include <path> [into <prefix>]`
 * 
 * `path` is a relative path (supports `..`) resolved against the current file
 * - if ending with `.ftl` the path will be used as is
 * - otherwise it is considered a directory, and the current language plus a `.ftl` extension will be appended to the path
 * 
 * An optional prefix can be specified with the `into` syntax.
 * In that case, every Fluent Message in the included file will be prefixed with the specified value plus a dash `-`,
 * which is useful for nesting localizers with variables or properties while reusing existing ftl files.
 */
class ExtendedFluentSource implements Source<String> {
	final path:String;
	final getSource:(getPath:(lang:String) -> String) -> Source<String>;

	public function new(path, getSource) {
		this.path = path;
		this.getSource = getSource;
	}

	public function fetch(language:String):Promise<String> {
		return load(path, language, []);
	}

	function load(path:String, lang:String, prefixes:Array<String>):Promise<String> {
		final source = getSource(language -> path.endsWith('.ftl') ? path : Path.join([path, '$language.ftl']));
		return source.fetch(lang).next(src -> follow(src, path, lang, prefixes));
	}

	function follow(source:String, path:String, lang:String, prefixes:Array<String>) {
		final regex = ~/^# @include ([^ ]+)( into (\w+))?$/;
		final promises = [];

		var start = 0;
		var end = 0;

		function add(s, ?e) {
			final sub = source.substring(s, e).trim();
			final matched = regex.match(sub);
			if (matched) {
				var rel = regex.matched(1).trim();
				if (!rel.endsWith('.ftl'))
					rel = Path.join([rel, '$lang.ftl']);

				final newPrefixes = switch regex.matched(3) {
					case null:
						prefixes;
					case prefix:
						prefixes.concat([prefix]);
				}

				final sections = [path.endsWith('.ftl') ? path.directory() : path, rel];
				promises.push(load(Path.join(sections).normalize(), lang, prefixes).next(appendPrefixes.bind(_, newPrefixes)));
			}
			return matched;
		}

		var ended = false;
		while ((end = source.indexOf('\n', start + 1)) != -1) {
			final added = add(start, end);
			start = end;
			if (!added) {
				ended = true; // skip the remaining of the file
				break;
			}
		}

		if (!ended)
			add(start);

		return Promise.inParallel(promises).next(list -> source + '\n' + list.join('\n'));
	}

	function appendPrefixes(source:String, prefixes:Array<String>):String {
		if (prefixes.length == 0)
			return source;
		final syntax:Dynamic = js.Lib.require('@fluent/syntax');
		final resource:{body:Array<Dynamic>} = syntax.parse(source);
		for (entry in resource.body) {
			if (js.Syntax.instanceof(entry, syntax.Message)) {
				entry.id = js.Syntax.code('new {0}.Identifier({1})', syntax, prefixes.concat([entry.id.name]).join('-'));
			}
		}
		return syntax.serialize(resource);
	}
}
