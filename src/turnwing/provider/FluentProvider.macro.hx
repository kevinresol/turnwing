package turnwing.provider;

import haxe.macro.Expr;
import haxe.macro.Type;
import tink.macro.BuildCache;
import turnwing.util.Prefix;

using tink.MacroApi;

class FluentProvider {
	public static function build() {
		return BuildCache.getType('turnwing.provider.FluentProvider', (ctx:BuildContext) -> {
			final name = ctx.name;
			final localeCt = ctx.type.toComplex();

			final validations = [];

			function generate(info:turnwing.Macro.LocaleInfo, prefix:Prefix) {
				for (entry in info.entries) {
					final fullname = prefix.add(entry.name, '-');
					switch entry.kind {
						case Term([]):
							validations.push(macro turnwing.provider.FluentProvider.Verification.nameOnly($v{fullname}));
						case Term(args):
							final variables = macro $a{args.map(arg -> macro $v{arg.name})};
							validations.push(macro new turnwing.provider.FluentProvider.Verification($v{fullname}, $variables));
						case Sub(_, info):
							generate(info, fullname);
					}
				}
			}

			generate(Macro.process(ctx.type, ctx.pos), new Prefix());

			final def = macro class $name extends turnwing.provider.FluentProvider.FluentProviderBase<$localeCt> {
				override function validate(ctx:turnwing.provider.FluentProvider.FluentContext) {
					final validations = $a{validations};
					for (v in validations)
						switch validateMessage(ctx, v.name, v.value) {
							case Some(error):
								return tink.core.Outcome.Failure(error);
							case None: // ok
						}
					return tink.core.Outcome.Success(ctx.bundle);
				}

				override function make(bundle:turnwing.provider.FluentProvider.FluentBundle):$localeCt
					return new turnwing.provider.FluentProvider.FluentLocale<$localeCt>(bundle, new turnwing.util.Prefix());
			}

			def.pack = ['turnwing', 'provider'];
			def;
		});
	}

	// https://github.com/HaxeFoundation/haxe/issues/9271
	public static function buildLocale() {
		return FluentLocale.build();
	}
}

class FluentLocale {
	public static function build() {
		return BuildCache.getType('turnwing.provider.FluentLocale', (ctx:BuildContext) -> {
			final name = ctx.name;
			final localeCt = ctx.type.toComplex();
			final localeTp = switch localeCt {
				case TPath(tp): tp;
				default: throw 'assert';
			}

			final info = Macro.process(ctx.type, ctx.pos);
			final inits = [];

			final def = macro class $name extends turnwing.provider.FluentProvider.FluentLocaleBase implements $localeTp {
				public function new(__bundle__, __prefix__) {
					super(__bundle__, __prefix__);
					@:mergeBlock $b{inits}
				}
			} // unbreak haxe-formatter (see: https://github.com/HaxeCheckstyle/haxe-formatter/issues/565)

			for (entry in info.entries) {
				final name = entry.name;

				switch entry.kind {
					case Term(args):
						final params = EObjectDecl([for (arg in args) {field: arg.name, expr: macro $i{arg.name}}]).at(entry.pos);
						final body = macro __exec__($v{entry.name}, $params);

						final f = body.func(args.map(a -> a.name.toArg(a.t.toComplex(), a.opt)), macro:String);
						def.fields.push({
							access: [APublic],
							name: name,
							kind: FFun(f),
							pos: entry.pos,
						});

					case Sub(access, info):
						final subLocaleCt = entry.type.toComplex();
						final factory = macro new turnwing.provider.FluentProvider.FluentLocale<$subLocaleCt>(__bundle__, __prefix__.add($v{entry.name}, '-'));
						final init = macro $i{name} = $factory;

						switch access {
							case Default:
								def.fields.push({
									access: [APublic],
									name: name,
									kind: FProp('default', 'null', subLocaleCt, null),
									pos: entry.pos,
								});
								inits.push(init);
							case Getter:
								def.fields.push({
									access: [APublic],
									name: name,
									kind: FProp('get', 'never', subLocaleCt, null),
									pos: entry.pos,
								});
								def.fields.push({
									access: [AInline],
									name: 'get_$name',
									kind: FFun(factory.func(subLocaleCt)),
									pos: entry.pos,
								});
							case Final:
								def.fields.push({
									access: [APublic, AFinal],
									name: name,
									kind: FVar(subLocaleCt, null),
									pos: entry.pos,
								});
								inits.push(init);
						}
				}
			}

			def.pack = ['turnwing', 'provider'];
			def;
		});
	}
}
