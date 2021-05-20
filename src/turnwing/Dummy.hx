package turnwing;

#if !macro
@:genericBuild(turnwing.Dummy.build())
class Dummy<T> {}
#else
import haxe.macro.Expr;
import turnwing.Macro.*;
import tink.macro.BuildCache;

using haxe.macro.Tools;
using tink.MacroApi;

class Dummy {
	public static function build() {
		return BuildCache.getType('turnwing.Dummy', (ctx:BuildContext) -> {
			final name = ctx.name;
			final ct = ctx.type.toComplex();
			final tp = switch ct {
				case TPath(p): p;
				case v:
					trace(v);
					throw 'assert';
			}

			final def = macro class $name implements $tp {
				public function new() {}
			}

			final info = process(ctx.type, ctx.pos);
			for (entry in info.entries) {
				def.fields.push({
					name: entry.name,
					pos: entry.pos,
					access: entry.kind.match(Sub(Final, _)) ? [APublic, AFinal] : [APublic],
					kind: switch entry.kind {
						case Sub(access, info):
							final ct = info.complex;
							access == Getter ? FProp('get', 'never', ct) : FVar(ct, macro new turnwing.Dummy<$ct>());
						case Term(args):
							FFun({
								args: args.map(arg -> {
									name: arg.name,
									opt: arg.opt,
									type: arg.t.toComplex(),
									meta: null,
									value: null
								}),
								ret: macro:String,
								expr: {
									final exprs = [
										(macro final buf = new StringBuf()),
										(macro buf.addChar('<'.code)),
										(macro buf.add($v{entry.name})),
									];
									for (arg in args)
										exprs.push(macro buf.add(' ' + $v{arg.name} + ':' + $i{arg.name}));
									exprs.push(macro buf.addChar('>'.code));
									exprs.push(macro return buf.toString());
									macro $b{exprs}
								}
							});
					}
				});
				
				switch entry.kind {
					case Sub(Getter, info):
						final ct = info.complex;
						def.fields.push({
							name: 'get_' + entry.name,
							pos: entry.pos,
							kind: FFun({
								args: [],
								expr: macro return new turnwing.Dummy<$ct>(),
							}),
						});
					case _:
				}
			}

			def;
		});
	}
}
#end
