package turnwing;

import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;
import tink.macro.BuildCache;
using tink.MacroApi;
using StringTools;

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
		var fields:Array<Field> = [];
		for(entry in process(type)) {
			fields.push({
				name: entry.name,
				pos: entry.pos,
				kind: FVar({
					var ct = entry.type.toComplex();
					entry.kind == Field ? ct : macro:turnwing.Data<$ct>;
				}, null),
			});
		}
		return fields;
	}
	
	static function getLocaleFields(type:Type, pos):Array<Field> {
		var fields:Array<Field> = [];
		var inits = [];
		for(entry in process(type)) {
			var name = entry.name;
			var type = entry.type;
			switch entry.prop {
				case Func(a):
					if(entry.kind == Field) {	
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
								ret: type.toComplex(),
								expr: macro return __template__.execute(__data__.$name, ${EObjectDecl(params).at(entry.pos)}),
							}),
							pos: entry.pos,
						});
					} else {
						entry.pos.error('Function returning sub-locale is not supported');
					}
				case Var(Getter):
					var ct = type.toComplex();
					fields.push({
						access: [APublic],
						name: name,
						kind: FProp('get', 'null', ct, null),
						pos: entry.pos,
					});
					fields.push({
						access: entry.kind == Field ? [AInline] : [],
						name: 'get_$name',
						kind: FFun({
							args: [],
							ret: null,
							expr:
								if(entry.kind == Field)
									macro return __data__.$name;
								else
									macro {
										if($i{name} == null)
											$i{name} = new turnwing.Localizer<$ct>(__data__.$name, __template__);
										return $i{name};
									}
						}),
						pos: entry.pos,
					});
				case Var(access = Default #if haxe4 | Final #end):
					var ct = type.toComplex();
					fields.push({
						access: access == Default ? [APublic] : [APublic, AFinal],
						name: name,
						kind: access == Default ? FProp('default', 'null', ct, null) : FVar(ct, null),
						pos: entry.pos,
					});
					inits.push(
						if(entry.kind == Field)
							macro $i{name} = __data__.$name;
						else
							macro $i{name} = new turnwing.Localizer<$ct>(__data__.$name, __template__)
					);
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
	
	public static function process(type:Type, homogenous = false):LocaleInfo {
		var cls = getInterface(type);
		var info = [];
		
		var prev = null;
		for(field in cls.fields.get()) {
			if(field.meta.has(':compilerGenerated')) continue; 
			
			var type = switch field.type {
				case TFun(_, t): t;
				case t: t;
			}
			var kind = switch type {
				case t = TInst(_.get() => cls, _) if(cls.isInterface): Sub(process(t, homogenous));
				case _: Field;
			}
			if(homogenous) {
				if(prev == null) prev = kind;
				else if(kind.getIndex() != prev.getIndex()) field.pos.error('Cannot mix sub-locale and locale fields.');
			}
			
			info.push({
				name: field.name,
				pos: field.pos,
				type: type,
				kind: kind,
				prop: switch field.type {
					case TFun(a, t): Func(a);
					case _: Var(getAccess(field));
				},
			});
		}
		return info;
	}
	
	static function getAccess(field:ClassField):VarRead {
		return switch field.kind {
			case FVar(AccCall, AccNever | AccNo): Getter;
			case FVar(AccNormal, AccNever | AccNo): Default;
			#if haxe4 case FVar(AccNormal, AccCtor) if(field.isFinal): Final; #end
			case _: field.pos.error('Locale interface can only define functions and properties with (default/get, null/never) access');
		}
	}
}

typedef LocaleInfo = Array<LocaleEntry>;
typedef LocaleEntry = {
	name:String,
	kind:EntryKind,
	prop:EntryProp,
	type:Type,
	pos:Position,
}

enum EntryProp {
	Func(args:Array<{name:String, opt:Bool, t:Type}>);
	Var(access:VarRead);
}

enum EntryKind {
	Sub(info:LocaleInfo);
	Field;
}

enum VarRead {
	Default;
	Getter;
	#if haxe4 Final; #end
}