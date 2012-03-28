package symbolic;

import symbolic.Expr;
using symbolic.Expr.ExprUtils;

import com.mindrocks.text.Parser;
using com.mindrocks.text.Parser;

import com.mindrocks.functional.Functional;
using com.mindrocks.functional.Functional;

using com.mindrocks.macros.LazyMacro;

using Lambda;

/*
	scalar values :: usual floats
	vector values :: [scalar scalar]
	matrix values :: [scalar scalar ; scalar scalar ]

	vardecl  :: decl identifier type
	variable :: identifier (non reserved)
	localvar :: let identifier = expr in expr

	relative vector :: relative variable expr

	operators :: x + y, x * y,x dot y, x cross y, [x], x outer y, |x|, unit x
	emulated operators :: x - y, x / y

	precedences ; usual suspects!

		unit <- highest
		*, /
		dot, cross
		outer
		+, -
*/

class ExprParser {
	static var identifierR = ~/[a-zA-Z_][a-zA-Z0-9_]*/;
	static var numberR = ~/[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?/;

	static var spaceP = " ".identifier();
	static var tabP = "\t".identifier();
	static var retP = ("\r".identifier().or("\n".identifier()));
	
	static var spacingP = [
		spaceP.oneMany(),
		tabP.oneMany(),
		retP.oneMany()
	].ors().many().lazyF();

	static function withSpacing<T>(p:Void->Parser<String,T>) return spacingP._and(p)

	static var lParP     = withSpacing("(".identifier());
	static var rParP     = withSpacing(")".identifier());
	static var lSquareP  = withSpacing("[".identifier());
	static var rSquareP  = withSpacing("]".identifier());
	static var semicolP  = withSpacing(";".identifier());
	static var equalsP   = withSpacing("=".identifier());
	static var addP      = withSpacing("+".identifier());
	static var subP      = withSpacing("-".identifier());
	static var mulP      = withSpacing("*".identifier());
	static var divP      = withSpacing("/".identifier());
	static var magP      = withSpacing("|".identifier());
	static var letP      = withSpacing("let".identifier());
	static var inP       = withSpacing("in".identifier());
	static var relativeP = withSpacing("relative".identifier());
	static var dotP      = withSpacing("dot".identifier());
	static var crossP    = withSpacing("cross".identifier());
	static var outerP    = withSpacing("outer".identifier());
	static var unitP     = withSpacing("unit".identifier());
	static var declP     = withSpacing("decl".identifier());

	//--------------------------------------------------------

	static var typeP = withSpacing(
		["scalar".identifier().then(function(_) return etScalar),
		 "vector".identifier().then(function(_) return etVector),
		 "matrix".identifier().then(function(_) return etMatrix)].ors()
	).tag("type name").lazyF();

	//--------------------------------------------------------

	static var identifierP = withSpacing(identifierR.regexParser()).tag("identifier");
	static var numberP = withSpacing(numberR.regexParser())
						.then(function (n) return Std.parseFloat(n))
						.tag("number");

	//--------------------------------------------------------

	static var identP = identifierP.tag("identifier");
	
	//--------------------------------------------------------

	static var scalarP = numberP.then(function (x) return eScalar(x)).tag("scalar");
	static var vectorP = lSquareP._and(numberP.and(numberP)).and_(rSquareP)
						.then(function (xy) return eVector(xy.a,xy.b))
						.tag("vector");
	static var matrixP = lSquareP._and(
							(numberP.and(numberP))
							.and_(semicolP)
							.and(numberP.and(numberP))
						).and_(rSquareP)
						.then(function (ab_cd)
							return eMatrix(ab_cd.a.a,ab_cd.a.b,
							               ab_cd.b.a,ab_cd.b.b)
						).tag("matrix");
	static var valueP = [scalarP,vectorP,matrixP].ors().tag("value").lazyF();

	//--------------------------------------------------------

	static var vardeclP = typeP.and(identP)
					 	 .then(function (nt) return { name : nt.b, type : nt.a })
						 .tag("variable- declaration").many();

	//--------------------------------------------------------

	// TODO not working
	static var magopP = magP._and(exprP.commit()).and_(magP)
						.then(function (e) return eMag(e))
						.lazyF();

	static var addopP = addP.then(function (_) return function (e1,e2) return eAdd(e1,e2));
	static var subopP = subP.then(function (_) return function (e1,e2) return eAdd(e1,eMul(eScalar(-1),e2)));
	static var binopP = chainl1(valueExprP, [addopP,subopP].ors()).lazyF();

	//--------------------------------------------------------

	static var valueExprP:Void->Parser<String,Expr> = 
					[ magopP, valueP ].ors().memo().tag("expression");

	static var exprP:Void->Parser<String,Expr> =
				    [ binopP,
					  valueExprP
				    ].ors().memo().tag("expression");

	//--------------------------------------------------------

	static var definitionP = vardeclP.commit().and(exprP.commit())
							.then(function (varexp) {
								var context = ExprUtils.emptyContext();
								for(vard in varexp.a)
									context.variableContext(vard.name,vard.type);
								
								return {context:context, constraint:varexp.b};
							});

	//--------------------------------------------------------

	static function chainl1<T>(p:Void->Parser<String,T>, op:Void->Parser<String,T->T->T>):Void->Parser<String,T> {
		function rest(x:T) {
			return op.andThen(function (f:T->T->T) {
				return p.andThen(function (y:T) {
					return rest(f(x,y));
				});
			}).or(x.success());
		}
		return p.andThen(function (x:T) return rest(x));
	}

	//--------------------------------------------------------

	static function tryParse<T>(str:String, parser:Parser<String,T>, withResult:T->Void, output:String->Void) {
//		try {
			var res = parser(str.reader());
			switch(res) {
				case Success(res, rest):
					var remaining = rest.rest();
					if(StringTools.trim(remaining).length==0) {
						trace("success");
					}else {
						trace("failed to parse " + remaining);
					}
					withResult(res);
				case Failure(err, rest, _):
					var p = rest.textAround();
					output(p.text);
					output(p.indicator);
					err.map(function (error) {
						output("Error at " + error.pos + " : " +error.msg);
					});
			}
//		}catch(e:Dynamic) {
//			trace("Error " + Std.string(e));
//		}
	}

	static public function test() {
		tryParse("
			[50 60] + [70 20] - [10 20]
		",
		exprP(),
		function (res) trace("Parsed " +Std.string(res)),
		function (str) trace(str)
		);
	}
}
