package turnwing.provider;

import haxe.macro.Expr;
import haxe.macro.Type;
import tink.macro.BuildCache;
import turnwing.util.Prefix;

using tink.MacroApi;

class FluentProvider {
	public static function build() {
		return BuildCache.getType('turnwing.provider.FluentProvider', (ctx:BuildContext) -> {
			var name = ctx.name;
			var localeCt = ctx.type.toComplex();

			var validations = [];

			function generate(info:turnwing.Macro.LocaleInfo, prefix:Prefix) {
				for (entry in info.entries) {
					var fullname = prefix.add(entry.name, '-');
					switch entry.kind {
						case Term(args):
							validations.push(macro {
								switch bundle.getMessage($v{fullname}) {
									case null: return tink.core.Outcome.Failure(new tink.core.Error('Missing Message "' + $v{fullname} + '"'));
									case message: // TODO: check function parameters
								}
							});
						case Sub(_, info):
							generate(info, fullname);
					}
				}
			}

			generate(Macro.process(ctx.type), new Prefix());

			var def = macro class $name extends turnwing.provider.FluentProvider.FluentProviderBase<$localeCt> {
				override function validate(bundle:turnwing.provider.FluentProvider.FluentBundle) {
					$b{validations};
					return tink.core.Outcome.Success(bundle);
				}

				override function make(bundle:turnwing.provider.FluentProvider.FluentBundle):$localeCt
					return new turnwing.provider.FluentProvider.FluentLocale<$localeCt>(bundle, new turnwing.util.Prefix());
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

			var def = macro class $name extends turnwing.provider.FluentProvider.FluentLocaleBase implements $localeTp {
				public function new(__bundle__, __prefix__) {
					super(__bundle__, __prefix__);
					@:mergeBlock $b{inits}
				}
			} // unbreak haxe-formatter (see: https://github.com/HaxeCheckstyle/haxe-formatter/issues/565)

			for (entry in info.entries) {
				var name = entry.name;

				switch entry.kind {
					case Term(args):
						var params = EObjectDecl([for (arg in args) {field: arg.name, expr: macro $i{arg.name}}]).at(entry.pos);
						var body = macro __bundle__.formatPattern(__bundle__.getMessage(__prefix__.add($v{entry.name}, '-')).value, $params);

						var f = body.func(args.map(a -> a.name.toArg(a.t.toComplex(), a.opt)), macro:String);
						def.fields.push({
							access: [APublic],
							name: name,
							kind: FFun(f),
							pos: entry.pos,
						});

					case Sub(access, info):
						var subLocaleCt = entry.type.toComplex();
						var factory = macro new turnwing.provider.FluentProvider.FluentLocale<$subLocaleCt>(__bundle__, __prefix__.add($v{entry.name}, '-'));
						var init = macro $i{name} = $factory;

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
