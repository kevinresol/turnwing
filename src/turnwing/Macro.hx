package turnwing;

import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;
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
					 throw ctx.type.getID() + ' should be an interface';
			}
			var dataCt = macro:turnwing.Data<$localeCt>;
			
			var def = macro class $name extends turnwing.Localizer.LocalizerBase<$dataCt> implements $localeTp {}
			def.fields = getLocaleFields(ctx.type, ctx.pos);
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
				kind: FVar(switch [field.kind, field.type.getID()] {
					case [FMethod(_), _], [FVar(_), 'String']: macro:String;
					case [FVar(_), _]: var ct = field.type.toComplex(); macro:turnwing.Data<$ct>;
				}, null),
				pos: field.pos,
			});
			
		return fields;
	}
	
	static function getLocaleFields(type:Type, pos):Array<Field> {
		var cls = getInterface(type);
		var fields:Array<Field> = [];
		
		var inits = [];
		
		for(field in cls.fields.get()) {
			var name = field.name;
			
			switch [field.type, field.kind] {
				case [TFun(a, ret), _]:
					
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
				
				case [t, FVar(AccCall, AccNever | AccNo)]:
					var ct = t.toComplex();
					fields.push({
						access: [APublic],
						name: name,
						kind: FProp('get', 'null', ct, null),
						pos: field.pos,
					});
					switch t.getID() {
						case 'String': 
							fields.push({
								access: [AInline],
								name: 'get_$name',
								kind: FFun({
									args: [],
									ret: null,
									expr: macro return __data__.$name,
								}),
								pos: field.pos,
							});
						default:
							fields.push({
								access: [],
								name: 'get_$name',
								kind: FFun({
									args: [],
									ret: null,
									expr: macro {
										if($i{name} == null)
											$i{name} = new turnwing.Localizer<$ct>(__data__.$name, __template__);
										return $i{name};
									}
								}),
								pos: field.pos,
							});
					}
				
				case [t, FVar(AccNormal, AccNever | AccNo)]:
					var ct = t.toComplex();
					fields.push({
						access: [APublic],
						name: name,
						kind: FProp('default', 'null', ct, null),
						pos: field.pos,
					});
					// the cast bypasses the "never" check
					inits.push(switch t.getID() {
						case 'String': macro $i{name} = __data__.$name;
						default: macro $i{name} = new turnwing.Localizer<$ct>(__data__.$name, __template__);
					});
				
				default:
					field.pos.error('Locale interface can only define functions and properties with (default/get, null/never) access');
			}
		}
		
		// constructor
		if(inits.length > 0)
			fields.push({
				access: [APublic],
				name: 'new',
				kind: FFun({
					args: [for(name in ['data', 'template']) {
						name: name,
						opt: false,
						type: null,
						meta: null,
						value: null
					}],
					ret: null,
					expr: macro {
						super(data, template);
						$b{inits};
					}
				}),
				pos: pos,
			});
			
		return fields;
	}
}