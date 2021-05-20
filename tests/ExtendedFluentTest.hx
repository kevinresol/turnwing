package;

import turnwing.source.*;
import ExtendedFluentTest.*;

using tink.CoreApi;

@:asserts
class ExtendedFluentTest {
	public static final FOO_EN = 'foo = Foo';
	public static final FOO_ZH = 'foo = 呼';
	public static final BAR_EN = 'bar = Bar';
	public static final BAR_ZH = 'bar = 巴';
	public static final BAZ_EN = 'baz = Baz';
	public static final BAZ_ZH = 'baz = 巴斯';
	public static final BAZ1_EN = 'baz1 = Baz1';
	public static final BAZ1_ZH = 'baz1 = 巴斯1';
	public static final PREFIX = 'myprefix';

	static final ESCAPED_NEWLINE = '\\n';

	public function new() {}

	// @formatter:off
	@:variant('foo', 'en', [ExtendedFluentTest.FOO_EN, ExtendedFluentTest.BAZ_EN])
	@:variant('bar', 'en', [ExtendedFluentTest.BAR_EN, ExtendedFluentTest.PREFIX + '-' + ExtendedFluentTest.BAZ_EN])
	@:variant('deep', 'en', ['deep-' + ExtendedFluentTest.BAR_EN, 'deep-' + ExtendedFluentTest.PREFIX + '-' + ExtendedFluentTest.BAZ_EN])
	@:variant('multi', 'en', [ExtendedFluentTest.BAZ_EN, ExtendedFluentTest.BAZ1_EN])
	
	@:variant('foo', 'zh', [ExtendedFluentTest.FOO_ZH, ExtendedFluentTest.BAZ_ZH])
	@:variant('bar', 'zh', [ExtendedFluentTest.BAR_ZH, ExtendedFluentTest.PREFIX + '-' + ExtendedFluentTest.BAZ_ZH])
	@:variant('deep', 'zh', ['deep-' + ExtendedFluentTest.BAR_ZH, 'deep-' + ExtendedFluentTest.PREFIX + '-' + ExtendedFluentTest.BAZ_ZH])
	@:variant('multi', 'zh', [ExtendedFluentTest.BAZ_ZH, ExtendedFluentTest.BAZ1_ZH])
	// @formatter:on
	public function basic(name:String, lang:String, expected:Array<String>) {
		final source = new ExtendedFluentSource(name, LocalStringSource.new);
		source.fetch(lang).next(source -> {
			final lines = source.split('\n');
			for (v in expected)
				asserts.assert(lines.contains(v), '"${lines.filter(line -> line.charCodeAt(0) != '#'.code).join(' $ESCAPED_NEWLINE ')}" contains "$v"');
			Noise;
		}).handle(asserts.handle);
		return asserts;
	}

	public function duplicate() {
		final source = new ExtendedFluentSource('duplicate', LocalStringSource.new);
		source.fetch('en').next(source -> {
			asserts.assert(occurrence(source, BAZ_EN) == 1);
			Noise;
		}).handle(asserts.handle);
		return asserts;
	}

	static function occurrence(source:String, query:String) {
		var start = 0;
		var count = 0;
		while (true) {
			switch source.indexOf(query, start) {
				case -1:
					return count;
				case i:
					count++;
					start = i + query.length;
			}
		}
	}
}

class LocalStringSource implements Source<String> {
	// @formatter:off
	static final map:Map<String, String> = [
		'foo/en.ftl' => '# @include ../baz\n$FOO_EN',
		'foo/zh.ftl' => '# @include ../baz\n$FOO_ZH',
		'bar/en.ftl' => '# @include ../baz into $PREFIX\n$BAR_EN',
		'bar/zh.ftl' => '# @include ../baz into $PREFIX\n$BAR_ZH',
		'baz/en.ftl' => '$BAZ_EN',
		'baz/zh.ftl' => '$BAZ_ZH',
		'baz1/en.ftl' => '$BAZ1_EN',
		'baz1/zh.ftl' => '$BAZ1_ZH',
		'deep/en.ftl' => '# @include ../bar into deep',
		'deep/zh.ftl' => '# @include ../bar into deep',
		'multi/en.ftl' => '# @include ../baz\n# @include ../baz1\nmulti = Multi',
		'multi/zh.ftl' => '# @include ../baz\n# @include ../baz1\nmulti = Multi',
		'transitive/en.ftl' => '# @include ../baz',
		'transitive/zh.ftl' => '# @include ../baz',
		'duplicate/en.ftl' => '# @include ../foo\n# @include ../baz',
		'duplicate/zh.ftl' => '# @include ../foo\n# @include ../baz',
	];
	// @formatter:on
	final getPath:String->String;

	public function new(getPath)
		this.getPath = getPath;

	public function fetch(language:String):Promise<String> {
		return map[getPath(language)];
	}
}
