package turnwing.provider;

import haxe.macro.Expr;
import haxe.macro.Type;
import tink.macro.BuildCache;

using tink.MacroApi;

class FluentProvider {
	public static function build() {
		return BuildCache.getType('turnwing.provider.FluentProvider', (ctx:BuildContext) -> {
			var name = ctx.name;
			var localeCt = ctx.type.toComplex();

			var info = Macro.process(ctx.type);
			var validations = [];

			for (entry in info.entries) {
				validations.push(macro {
					switch bundle.getMessage($v{entry.name}) {
						case null: return tink.core.Outcome.Failure(new tink.core.Error('Missing Message "' + $v{entry.name} + '"'));
						case message: // ok
					}
				});
			}

			var def = macro class $name extends turnwing.provider.FluentProvider.FluentProviderBase<$localeCt> {
				override function validate(bundle:turnwing.provider.FluentProvider.FluentBundle) {
					$b{validations};
					return tink.core.Outcome.Success(bundle);
				}

				override function make(bundle:turnwing.provider.FluentProvider.FluentBundle):$localeCt

					return new turnwing.provider.FluentProvider.FluentLocale<$localeCt>(bundle);
			}

			def.pack = ['turnwing', 'provider'];
			def;
		});
	}
}

class FluentLocale {
	public static function build() {
		return BuildCache.getType('turnwing.provider.FluentLocale', (ctx:BuildContext) -> {
			var name = ctx.name;
			var localeCt = ctx.type.toComplex();
			var localeTp = switch localeCt {
				case TPath(tp): tp;
				default: throw 'assert';
			}

			var info = Macro.process(ctx.type);
			var inits = [];

			var def = macro class $name extends turnwing.provider.FluentProvider.FluentLocaleBase implements $localeTp{} // unbreak haxe-formatter (see: https://github.com/HaxeCheckstyle/haxe-formatter/issues/565)

			for (entry in info.entries) {
				var name = entry.name;

				switch entry.kind {
					case Term(args):
						var params = EObjectDecl([for (arg in args) {field: arg.name, expr: macro $i{arg.name}}]).at(entry.pos);
						var body = macro __bundle__.formatPattern(__bundle__.getMessage($v{entry.name}).value, $params);

						var f = body.func(args.map(a -> a.name.toArg(a.t.toComplex(), a.opt)), macro:String);
						def.fields.push({
							access: [APublic],
							name: name,
							kind: FFun(f),
							pos: entry.pos,
						});

					case Sub(access, info):
				}
			}

			def.pack = ['turnwing', 'provider'];
			def;
		});
	}
}
