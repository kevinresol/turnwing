package turnwing.provider;

import haxe.macro.Expr;
import haxe.macro.Type;
import tink.macro.BuildCache;

using tink.MacroApi;

class JsonProvider {
	public static function build() {
		return BuildCache.getType('turnwing.provider.JsonProvider', (ctx:BuildContext) -> {
			var name = ctx.name;
			var localeCt = ctx.type.toComplex();
			var dataCt = macro:turnwing.provider.JsonProvider.JsonData<$localeCt>;

			var def = macro class $name extends turnwing.provider.JsonProvider.JsonProviderBase<$localeCt, $dataCt> {
				override function parse(v:String)
					return tink.Json.parse((v : $dataCt));

				override function make(data:$dataCt):$localeCt
					return new turnwing.provider.JsonProvider.JsonLocale<$localeCt>(template, data);
			}

			def.pack = ['turnwing', 'provider'];
			def;
		});
	}

	// https://github.com/HaxeFoundation/haxe/issues/9271
	public static function buildLocale() {
		return JsonLocale.build();
	}

	// https://github.com/HaxeFoundation/haxe/issues/9271
	public static function buildData() {
		return JsonData.build();
	}
}

class JsonLocale {
	public static function build() {
		return BuildCache.getType('turnwing.provider.JsonLocale', (ctx:BuildContext) -> {
			var name = ctx.name;
			var localeCt = ctx.type.toComplex();
			var localeTp = switch localeCt {
				case TPath(tp): tp;
				default: throw 'assert';
			}
			var dataCt = macro:turnwing.provider.JsonProvider.JsonData<$localeCt>;

			var info = Macro.process(ctx.type);
			var inits = [];

			var def = macro class $name extends turnwing.provider.JsonProvider.JsonLocaleBase<$dataCt> implements $localeTp {
				public function new(__template__, __data__) {
					super(__template__, __data__);
					@:mergeBlock $b{inits}
				}
			} // unbreak haxe-formatter (see: https://github.com/HaxeCheckstyle/haxe-formatter/issues/565)

			for (entry in info.entries) {
				var name = entry.name;

				switch entry.kind {
					case Term(args):
						var params = EObjectDecl([for (arg in args) {field: arg.name, expr: macro $i{arg.name}}]).at(entry.pos);
						var body = macro __template__.execute(__data__.$name, $params);
						var f = body.func(args.map(a -> a.name.toArg(a.t.toComplex(), a.opt)), macro:String);
						def.fields.push({
							access: [APublic],
							name: name,
							kind: FFun(f),
							pos: entry.pos,
						});

					case Sub(access, info):
						var subLocaleCt = entry.type.toComplex();
						var factory = macro new turnwing.provider.JsonProvider.JsonLocale<$subLocaleCt>(__template__, __data__.$name);
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

class JsonData {
	public static function build() {
		return BuildCache.getType('turnwing.provider.JsonData', function(ctx:BuildContext) {
			return {
				fields: getDataFields(ctx.type),
				name: ctx.name,
				pack: ['turnwing', 'provider'],
				pos: ctx.pos,
				kind: TDStructure,
			}
		});
	}

	static function getDataFields(type:Type):Array<Field> {
		var fields:Array<Field> = [];
		var info = Macro.process(type);
		for (entry in info.entries) {
			var ct = entry.type.toComplex();
			fields.push({
				name: entry.name,
				pos: entry.pos,
				kind: FVar(entry.kind.match(Term(_)) ? macro:String : macro:turnwing.provider.JsonProvider.JsonData<$ct>, null),
			});
		}
		return fields;
	}
}
