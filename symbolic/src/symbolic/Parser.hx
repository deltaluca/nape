package symbolic;

import symbolic.Expr;

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

	static var spaceP = " ".identifier().lazyF();
	static var tabP = "\t".identifier().lazyF();
	static var retP = ("\r".identifier().or("\n".identifier())).lazyF();
	
	static var spacingP = [
		spaceP.oneMany(),
		tabP.oneMany(),
		retP.oneMany()
	].ors().many().lazyF();

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

	static var typeP = withSpacing(
		["scalar".identifier(),
		 "vector".identifier(),
		 "matrix".identifier()].ors()
	);

	static var identifierP = withSpacing(identifierR.regexParser()).tag("identifier").lazyF();

	static var identP = identifierP.tag("identifier").lazyF();
	static var numberP = withSpacing(numberR.regexParser())
						.then(function (n) return Std.parseFloat(n))
						.tag("number").lazyF();
	
	static var scalarP = numberP.then(function (x) return eScalar(x)).tag("scalar").lazyF();
	static var vectorP = lSquareP._and(numberP.and(numberP)).and_(rSquareP)
						.then(function (xy) return eVector(xy.a,xy.b))
						.tag("vector").lazyF();
	static var matrixP = lSquareP._and(
							(numberP.and(numberP))
							.and_(semicolP)
							.and(numberP.and(numberP))
						).and_(rSquareP)
						.then(function (ab_cd)
							return eMatrix(ab_cd.a.a,ab_cd.a.b,
							               ab_cd.b.a,ab_cd.b.b)
						).tag("matrix").lazyF();
	static var valueP = [scalarP,vectorP,valueP].ors().lazyF();

	static function withSpacing<T>(p:Void->Parser<String,T>) return spacingP._and(p).lazyF()

}
