package turnwing.provider;

import haxe.DynamicAccess;
import turnwing.source.Source;
import turnwing.util.Prefix;

/**
 * FluentProvider consumes the FTL syntax.
 * Each message id corresponds to the function name of the Locale interface.
 * Nested interfaces are represented as prefixed message ids (delimited with a dash).
 *
 * Example:
 * ```ftl
 * plain = plain value
 * parametrized = parameterized { $variableName }
 * nested-another = value
 * ```
 */
@:genericBuild(turnwing.provider.FluentProvider.build())
class FluentProvider<Locale> {}

@:genericBuild(turnwing.provider.FluentProvider.buildLocale())
class FluentLocale<Locale> {}

class FluentProviderBase<Locale> implements Provider<Locale> {
	final source:Source<String>;
	final opt:{?useIsolating: Bool};

	public function new(source, ?opt) {
		this.source = source;
		if (opt != null)
			this.opt = opt; // let it remain undefined otherwise the js lib will choke
	}

	public function prepare(language:String):Promise<Locale>
		return source.fetch(language).next(bundle.bind(language)).next(make);

	function bundle(language:String, ftl:String):Outcome<FluentBundle, Error> {
		return if (ftl == null) {
			Failure(new Error('Empty ftl data'));
		} else {
			final ctx = new FluentContext(ftl, language, opt);
			validate(ctx);
		}
	}

	function validate(ctx:FluentContext):Outcome<FluentBundle, Error>
		throw 'abstract';

	// note: suppliedVariables is the list of argument names specified in the Locale interface
	function validateMessage(ctx:FluentContext, id:String, suppliedVariables:Array<String>):Option<Error> {
		return switch ctx.bundle.getMessage(id) {
			case null:
				Some(Error.withData('Missing Message "$id"', {source: ctx.source}));
			case message:
				validatePattern(ctx.bundle, message.value, 'Message "$id"', suppliedVariables);
		}
	}

	// TODO: complete the validation (rescusively)
	function validatePattern(bundle:FluentBundle, pattern:Pattern, location:String, suppliedVariables:Array<String>):Option<Error> {
		if (Std.is(pattern, Array)) {
			for (element in (pattern : Array<PatternElement>))
				switch (element : Expression).type {
					case null: // plain String
					case 'select':
						final select:SelectExpression = cast element;
					case 'var':
						final variable:VariableReference = cast element;
						if (suppliedVariables.indexOf(variable.name) == -1)
							return Some(new Error('Superfluous variable "${variable.name}". (Not provided in the Locale interface)'));
					case 'term':
						final term:TermReference = cast element;
						if (!bundle._terms.has('-' + term.name))
							return Some(new Error('Term "${term.name}" does not exist. (Required by $location)'));
					case 'mesg':
						final message:MessageReference = cast element;
					case 'func':
						final func:FunctionReference = cast element;
					case 'narg':
						final narg:NamedArgument = cast element;
					case 'str':
						final str:StringLiteral = cast element;
					case 'num':
						final num:NumberLiteral = cast element;
				}
		}
		return None;
	}

	function make(bundle:FluentBundle):Locale
		throw 'abstract';
}

class FluentContext {
	public final source:String;
	public final resource:FluentResource;
	public final bundle:FluentBundle;
	
	public function new(ftl, language, opt) {
		source = ftl;
		resource = new FluentResource(ftl);
		bundle = new FluentBundle(language, opt);
		bundle.addResource(resource);
	}
}

class FluentLocaleBase {
	final __bundle__:FluentBundle;
	final __prefix__:Prefix;

	public function new(bundle, prefix) {
		__bundle__ = bundle;
		__prefix__ = prefix;
	}

	function __exec__(id:String, params:Dynamic) {
		return __bundle__.formatPattern(__bundle__.getMessage(__prefix__.add(id, '-')).value, __sanitize__(params));
	}
	
	function __sanitize__(params:DynamicAccess<Dynamic>) {
		final ret = new DynamicAccess<Dynamic>();
		for(field => value in params) {
			// Fluent does not support boolean param, we change it to 0/1
			ret[field] = Type.typeof(value) == TBool ? (value ? 1 : 0) : value;
		}
		return ret;
	}
}

abstract Verification(Array<Dynamic>) {
	public var name(get, never):String;
	public var value(get, never):Array<String>;

	inline function get_name()
		return this[0];

	inline function get_value():Array<String>
		return untyped (this[1] || []);

	@:from
	public static inline function nameOnly(name:String):Verification
		return cast [name];

	public inline function new(name:String, value:Array<String>)
		this = [name, value];
}

// JS Externs below:

@:jsRequire('@fluent/bundle', 'FluentBundle')
extern class FluentBundle {
	final _terms:js.lib.Map<String, Term>;
	final _messages:js.lib.Map<String, Message>;

	function new(lang:String, ?opts:{});
	function addResource(res:FluentResource):Array<js.lib.Error>;
	function getMessage(id:String):Message;
	function formatPattern(pattern:Pattern, params:Dynamic):String;
}

@:jsRequire('@fluent/bundle', 'FluentResource')
extern class FluentResource {
	function new(ftl:String);
}

typedef Message = {
	id:String,
	value:Pattern,
}

typedef Term = {
	id:String,
	value:Pattern,
}

typedef Pattern = haxe.extern.EitherType<String, Array<PatternElement>>;
typedef PatternElement = haxe.extern.EitherType<String, Expression>;

typedef Expression = {
	?type:String,
}

typedef SelectExpression = Expression & {
	selector:Expression,
	variants:Array<Variant>,
	star:Int,
}

typedef VariableReference = Expression & {
	name:String,
}

typedef TermReference = Expression & {
	name:String,
	attr:String,
	args:Array<haxe.extern.EitherType<Expression, NamedArgument>>,
}

typedef MessageReference = Expression & {
	name:String,
	attr:String,
}

typedef FunctionReference = Expression & {
	name:String,
	args:Array<haxe.extern.EitherType<Expression, NamedArgument>>,
};

typedef Variant = Expression & {
	value:Pattern,
}

typedef NamedArgument = Expression & {
	name:String,
	value:Literal,
}

typedef Literal = haxe.extern.EitherType<StringLiteral, NumberLiteral>;

typedef StringLiteral = Expression & {
	value:String,
}

typedef NumberLiteral = Expression & {
	value:Int,
	precision:Int,
}
