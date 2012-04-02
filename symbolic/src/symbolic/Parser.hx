package symbolic;

import symbolic.Expr;
using symbolic.Expr.ExprUtils;

import com.mindrocks.text.Parser;
using com.mindrocks.text.Parser;

import com.mindrocks.functional.Functional;
using com.mindrocks.functional.Functional;

using com.mindrocks.macros.LazyMacro;

import com.mindrocks.text.ParserMonad;
using com.mindrocks.text.ParserMonad;

using Lambda;

/*
	body decl :: body name

	scalar values :: usual floats
	vector values :: [scalar scalar]
	matrix values :: [scalar scalar ; scalar scalar ]

	vardecl  :: type (identifier [-> expr]?)+
	variable :: identifier (non reserved)
	localvar :: let identifier = expr in expr

	relative vector :: relative variable expr

	operators :: x + y, x * y,x dot y, x cross y, [x], x outer y, |x|, unit x
	emulated operators :: x - y, x / y

	precedences ; usual suspects!

		unit <- highest
		relative
		*, /
		dot, cross
		outer
		+, -
		let
*/

class ConstraintParser {
	static var identifierR = ~/[a-zA-Z_][a-zA-Z0-9_.]*/;
	static var numberR = ~/[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?/;

	//whitespace
	static var spaceP = " ".identifier();
	static var tabP = "\t".identifier();
	static var retP = ("\r".identifier().or("\n".identifier()));

	//comments
	static var commentR = ~/#.*/;
	
	static var spacingP = [
		spaceP.oneMany(),
		tabP.oneMany(),
		retP.oneMany(),
		commentR.regexParser().oneMany()
	].ors().many();

	static function withSpacing<T>(p:Void->Parser<String,T>) return spacingP._and(p)

	//--------------------------------------------------------

	//produce a left-recursive application of possible infix binary operators to 'p' parsers
	static function chainl1<T>(p:Void->Parser<String,T>, op:Void->Parser<String,T->T->T>):Void->Parser<String,T> {
		function rest(x:T) return ParserM.dO({
			f <= op;
			y <= p;
			rest(f(x,y));
		}).or(x.success());

		return ParserM.dO({ x <= p; rest(x); });
	}

	static function plussep<T,D>(p:Void->Parser<String,T>, sep:Void->Parser<String,D>):Void->Parser<String,Array<T>> {
		function rest(x:Array<T>) return ParserM.dO({
			_ <= sep;
			y <= p;
			rest(x.concat([y]));
		}).or(x.success());
	
		return ParserM.dO({ x <= p; rest([x]); });
	}

	//--------------------------------------------------------
	//operators and key words

	static var lParP     = withSpacing("(".identifier());
	static var rParP     = withSpacing(")".identifier());
	static var lBraceP   = withSpacing("{".identifier());
	static var rBraceP   = withSpacing("}".identifier());
	static var lSquareP  = withSpacing("[".identifier());
	static var rSquareP  = withSpacing("]".identifier());
	static var semicolP  = withSpacing(";".identifier());
	static var commaP    = withSpacing(",".identifier());
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
	static var idscalarP = withSpacing("scalar".identifier());
	static var idvectorP = withSpacing("vector".identifier());
	static var idrowP    = withSpacing("rowvector".identifier());
	static var idmatrixP = withSpacing("matrix".identifier());
	static var delP      = withSpacing("->".identifier());
	static var bodyP     = withSpacing("body".identifier());

	//--------------------------------------------------------
	//value type

	static var typeP = withSpacing(
		[ParserM.dO({ idscalarP; ret(etScalar); }),
		 ParserM.dO({ idvectorP; ret(etVector); }),
		 ParserM.dO({ idrowP; ret(etRowVector); }),
		 ParserM.dO({ idmatrixP; ret(etMatrix); })].ors()
	).tag("type name");

	//--------------------------------------------------------
	//atoms

	static var identP = withSpacing(identifierR.regexParser()).tag("identifier");
	static var numberP = withSpacing(ParserM.dO({
		x <= numberR.regexParser();
		ret(Std.parseFloat(x));
	})).tag("number");

	//--------------------------------------------------------
	//value literals

	static var scalarP = ParserM.dO({
		x <= numberP;
		ret(eScalar(x));
	}).tag("scalar");

	static var vectorP = ParserM.dO({
		lSquareP; x <= numberP; y <= numberP; rSquareP;
		ret(eVector(x,y));
	}).tag("vector");

	static var rowvectorP = ParserM.dO({
		lSquareP; x <= numberP; semicolP; y <= numberP; rSquareP;
		ret(eRowVector(x,y));
	}).tag("rowvector");

	static var matrixP = ParserM.dO({
		lSquareP; a <= numberP; b <= numberP;
		semicolP; c <= numberP; d <= numberP; rSquareP;
		ret(eMatrix(a,b,c,d));
	}).tag("matrix");

	static var blockP = ParserM.dO({
		lBraceP; xs <= exprP.many(); rBraceP;
		ret(eBlock(xs));
	}).tag("block");

	static var valueP = [scalarP,vectorP,rowvectorP,matrixP,blockP].ors().tag("value");

	//--------------------------------------------------------
	//variable and body declarations

	static var vardeclP = ParserM.dO({
		type <= typeP;
		decls <= plussep(ParserM.dO({
			name <= identP;
			del  <= ParserM.dO({
				delP;
				e <= exprP;
				ret(e);
			}).option();
			ret({name:name, type:type, del:del});
		}), commaP);
		ret(decls);
	}).tag("variable declaration");

	static var bodydeclP = ParserM.dO({
		bodyP;
		names <= plussep(ParserM.dO({
			name <= identP;
			ret({name:name, type:null, del:null});
		}), commaP);
		ret(names);
	}).tag("body declaration");

	static var declarationsP = [vardeclP, bodydeclP].ors();

	//--------------------------------------------------------
	//expression

	// ( expr ), | expr |, [ expr ], value, variable
	static var expr0P = [
		ParserM.dO({ lParP; e <= exprP; rParP; ret(e); }),
		ParserM.dO({ lSquareP; e <= exprP; rSquareP; ret(ePerp(e)); }),
		valueP,
		ParserM.dO({ n <= identP; ret(eVariable(n)); }),
		ParserM.dO({ magP; e <= exprP; magP; ret(eMag(e)); })
	].ors();

	// unit expr0 | expr0
	static var expr1P = ParserM.dO({
		unitP; e <= expr0P; ret(eUnit(e));
	}).or(expr0P);

	// relative n expr | expr1
	static var expr1bP = ParserM.dO({
		relativeP; n <= identP; e <= exprP;
		ret(eRelative(n,e));
	}).or(expr1P);

	// chain (*,/) expr1b
	static var mulopP = ParserM.dO({ mulP; ret(function (e1,e2) return eMul(e1,e2)); });
	static var divopP = ParserM.dO({ divP; ret(function (e1,e2) return eMul(e1,eInv(e2))); });
	static var expr2P = chainl1(expr1bP, [mulopP,divopP].ors());

	// chain (dot,cross) expr2
	static var dotopP = ParserM.dO({ dotP;   ret(function (e1,e2) return eDot  (e1,e2)); });
	static var crsopP = ParserM.dO({ crossP; ret(function (e1,e2) return eCross(e1,e2)); });
	static var expr3P = chainl1(expr2P, [dotopP,crsopP].ors());

	// chain (outer) expr3
	static var outeropP = ParserM.dO({ outerP; ret(function (e1,e2) return eOuter(e1,e2)); });
	static var expr4P = chainl1(expr3P, outeropP);

	// chain (+,-) expr4
	static var addopP = ParserM.dO({ addP; ret(function (e1,e2) return eAdd(e1,e2)); });
	static var subopP = ParserM.dO({ subP; ret(function (e1,e2) return eAdd(e1,eMul(eScalar(-1),e2))); });
	static var expr5P = chainl1(expr4P, [addopP,subopP].ors());

	// let expr (right associative)
	static var exprP = ParserM.dO({
		letP; n <= identP; equalsP; e1 <= exprP; inP; e2 <= exprP;
		ret(eLet(n,e1,e2));
	}).or(expr5P).tag("expression");

	//--------------------------------------------------------
	//full constraint definition

	static var constraintP = ParserM.dO({
		vars <= declarationsP.many();
		posc <= exprP;
		ret({
			var context:Context = ExprUtils.emptyContext();
			var bodies = [];
			for(vs in vars) { for(v in vs) {
				if(v.type==null) bodies.push(v.name);
				else {
					var del = switch(v.del) {
						case Some(x): x;
						default: null;
					}
					context.variableContext(v.name, v.type, del);
				}
			} }
			{ bodies: bodies, context: context, posc : posc };
		});
	}).memo();

	//--------------------------------------------------------

	public static function parse(constraint:String):{context:Context, posc:Expr, bodies:Array<String>} {
		switch(constraintP()(constraint.reader())) {
			case Success(res,resti):
				var rest = resti.rest();
				if(StringTools.trim(rest).length!=0)
					throw "Error: Parsing succeeded with res: '"+Std.string(res)+"', but remaining string: '"+rest+"' was not parsed";
				return res;
			case Failure(err,resti,_):
				var rest = resti.textAround();
				throw "Error: Failed to parse with err: '"+err+"' and remaining unparsed string: '"+rest+"'";
		}
		return null;
	}
}
