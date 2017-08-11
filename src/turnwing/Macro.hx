package turnwing;

import haxe.macro.Expr;
import haxe.macro.Type;
import tink.macro.BuildCache;
using tink.MacroApi;

class Macro {
	public static function buildManager() {
		return BuildCache.getType('turnwing.Manager', function(ctx:BuildContext) {
			var name = ctx.name;
			var localeCt = ctx.type.toComplex();
			var dataCt = macro:turnwing.Data<$localeCt>;
			
			var def = macro class $name extends turnwing.Manager.ManagerBase<$localeCt, $dataCt> {
				override function createLocale(data:$dataCt):$localeCt {
					return new turnwing.Localizer<$localeCt>(data, template);
				}
			}
			def.pack = ['turnwing'];
			return def;
		});
	}
	
	public static function buildLocalizer() {
		return BuildCache.getType('turnwing.Localizer', function(ctx:BuildContext) {
			var name = ctx.name;
			var localeCt = ctx.type.toComplex();
			var localeTp = switch ctx.type {
				case TInst(cls, _) if(cls.get().isInterface):
					switch localeCt {
						case TPath(tp): tp;
						default: throw 'assert';
					}
				default:
					 throw ctx.type.getID() + ' show be an interface';
			}
			var dataCt = macro:turnwing.Data<$localeCt>;
			
			var def = macro class $name extends turnwing.Localizer.LocalizerBase<$dataCt> implements $localeTp {}
			def.fields = getLocaleFields(ctx.type);
			def.pack = ['turnwing'];
			return def;
		});
	}
	
	public static function buildData() {
		return BuildCache.getType('turnwing.Data', function(ctx:BuildContext) {
			return {
				fields: getDataFields(ctx.type),
				name: ctx.name,
				pack: ['turnwing'],
				pos: ctx.pos,
				kind: TDStructure,
			}
		});
	}
	
	static function getInterface(type:Type):ClassType
		return switch type {
			case TInst(_.get() => cls, _) if(cls.isInterface):
				cls;
			default:
				throw type.getID() + ' show be an interface';
		}
	
	static function getDataFields(type:Type):Array<Field> {
		var cls = getInterface(type);
		var fields:Array<Field> = [];
		
		for(field in cls.fields.get())
			fields.push({
				name: field.name,
				kind: FVar(macro:String, null),
				pos: field.pos
			});
			
		return fields;
	}
	
	static function getLocaleFields(type:Type):Array<Field> {
		var cls = getInterface(type);
		var fields:Array<Field> = [];
		
		for(field in cls.fields.get())
			switch field.type {
				case TFun(a, ret):
					
					var name = field.name;
					var args:Array<FunctionArg> = [];
					var params = [];
					
					for(arg in a) {
						args.push({
							name: arg.name,
							opt: arg.opt,
							type: arg.t.toComplex(),
						});
						params.push({
							field: arg.name,
							expr: macro $i{arg.name},
						});
					}
				
					fields.push({
						access: [APublic],
						name: name,
						kind: FFun({
							args: args,
							ret: macro:String,
							expr: macro return __template__.execute(__data__.$name, ${EObjectDecl(params).at(field.pos)}),
						}),
						pos: field.pos,
					});
					
				default:
					field.pos.error('Locale interface can only define functions');
			}
			
		return fields;
	}
}