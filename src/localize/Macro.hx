package localize;

import haxe.macro.Expr;
import haxe.macro.Type;
import tink.macro.BuildCache;
using tink.MacroApi;

class Macro {
	public static function buildManager() {
		return BuildCache.getType('localize.Manager', function(ctx:BuildContext) {
			var name = ctx.name;
			var localeType = ctx.type;
			var localeCt = localeType.toComplex();
			var dataCt = macro:localize.Data<$localeCt>;
			
			var def = macro class $name extends localize.Manager.ManagerBase<$localeCt, $dataCt> {
				override function createLocale(data:$dataCt):$localeCt {
					return new localize.Localizer<$localeCt, $dataCt>(data, template);
				}
			}
			def.pack = ['localize'];
			return def;
		});
	}
	
	public static function buildLocalizer() {
		return BuildCache.getType2('localize.Localizer', function(ctx:BuildContext2) {
			var name = ctx.name;
			var localeTp = switch ctx.type {
				case TInst(cls, _) if(cls.get().isInterface):
					switch ctx.type.toComplex() {
						case TPath(tp): tp;
						default: throw 'assert';
					}
				default:
					 throw ctx.type.getID() + ' show be an interface';
			}
			var dataType = ctx.type2;
			var dataCt = dataType.toComplex();
			
			var def = macro class $name extends localize.Localizer.LocalizerBase<$dataCt> implements $localeTp {}
			def.fields = getLocaleFields(ctx.type);
			def.pack = ['localize'];
			return def;
		});
	}
	
	public static function buildData() {
		return BuildCache.getType('localize.Data', function(ctx:BuildContext) {
			return {
				fields: getDataFields(ctx.type),
				name: ctx.name,
				pack: ['localize'],
				pos: ctx.pos,
				kind: TDStructure,
			}
		});
	}
	
	public static function buildJsonProvider() {
		return BuildCache.getType('localize.provider.JsonProvider', function(ctx:BuildContext) {
			var name = ctx.name;
			var ct = ctx.type.toComplex();
			
			var def = macro class $name extends localize.provider.JsonProvider.JsonProviderBase<$ct> {
				override function fetch(language:String):tink.core.Promise<$ct>
					return reader.read(language).next(function(raw) return tink.Json.parse((raw:$ct)));
			}
			
			def.pack = ['localize'];
			return def;
		});
	}
	
	static function getDataFields(type:Type):Array<Field> {
		return switch type {
			case TInst(_.get() => cls, _) if(cls.isInterface):
				var fields:Array<Field> = [];
				
				for(field in cls.fields.get())
					fields.push({
						name: field.name,
						kind: FVar(macro:String, null),
						pos: field.pos
					});
					
				fields;
				
			default:
				throw type.getID() + ' show be an interface';
		}
	}
	
	static function getLocaleFields(type:Type)
		return switch type {
			case TInst(_.get() => cls, _) if(cls.isInterface):
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
					
				fields;
				
			default:
				throw type.getID() + ' show be an interface';
		}
}