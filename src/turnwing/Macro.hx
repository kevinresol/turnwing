package turnwing;

import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;
import tink.macro.BuildCache;

using tink.MacroApi;
using StringTools;

class Macro {
	public static inline function process(type:Type, pos:Position, homogenous = false):LocaleInfo {
		return processInterface(getInterface(type, pos));
	}

	public static function processInterface(cls:ClassType, homogenous = false):LocaleInfo {
		var entries = [];

		var prev = null;
		for (field in cls.fields.get()) {
			if (field.meta.has(':compilerGenerated')) // getters/setters
				continue;

			var kind = switch field.type {
				case TFun(args, t):
					if (t.getID() == 'String') {
						Term(args);
					} else {
						field.pos.error('Function must return string');
					}

				case TInst(_.get() => cls, params):
					if (!cls.isInterface) {
						field.pos.error('Field must be interface');
					} else if (params.length > 0) {
						field.pos.error('Paramterized interface is not supported');
					} else {
						Sub(getAccess(field), processInterface(cls));
					}

				case v:
					field.pos.error('Unsupported type');
			}

			entries.push({
				name: field.name,
				pos: field.pos,
				type: field.type,
				kind: kind,
			});
		}
		return {type: cls, entries: entries};
	}

	static function getInterface(type:Type, pos:Position):ClassType {
		return switch type {
			case TInst(_.get() => cls, _) if (cls.isInterface):
				cls;
			default:
				pos.error(type.getID() + ' should be an interface');
		}
	}

	static function getAccess(field:ClassField):VarRead {
		return switch field.kind {
			case FVar(AccCall, AccNever | AccNo): Getter;
			case FVar(AccNormal, AccNever | AccNo): Default;
			#if haxe4
			case FVar(AccNormal, AccCtor) if (field.isFinal): Final;
			#end
			case _: field.pos.error('Locale interface can only define functions and properties with (default/get, null/never) access');
		}
	}
}

typedef LocaleInfo = {
	type:ClassType,
	entries:Array<LocaleEntry>,
}

typedef LocaleEntry = {
	name:String,
	kind:EntryKind,
	type:Type,
	pos:Position,
}

enum EntryKind {
	Sub(access:VarRead, info:LocaleInfo); // must not be function
	Term(args:Array<{name:String, opt:Bool, t:Type}>); // must be function
}

enum VarRead {
	Default;
	Getter;
	#if haxe4
	Final;
	#end
}
