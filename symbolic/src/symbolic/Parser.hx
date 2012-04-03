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
	# this is a comment
	# body declarations
	body name (, name)*
	
	# variable declarations
	scalar|vector name (= default-literal) (-> time-derivative)? # and many allowed
	
	# constraint expression
	constraint expression

	# constraint/variable limits (optional; default 0's)
	# the types of min-expression max-expressino must
	#     match the variable|constraint, with <= >=
	#     done on seperate values of non-scalars
	# limits for variables checked in verify() step of constraint
	limit expression min-expression max-expression
	
	# expression may be:
	# a literal
	inf
	eps
	scalar
	[ scalar scalar]
	[ scalar scalar ; scalar scalar ]
	[ scalar ; scalar ]
	
	# a block expression
	{ expression* }

	# a let expression
	let name = expression in expression

	# with operators (defined in order of highest precedence to lowest)
	| expression | # magnitude (of a vector/scalar)
    [ expression ] # perpendicular-vector (of a vector)
    unit expression # unit of a vector/scalar (sign function on scalar)
    relative variable expression # define vector-expression as being in a local coordinate system who's rotation is defined by the given variable
	a * b, a / b # multiplication, division
	a dot b, a cross b # dot product and cross product defined like a dot b = tranpose(a)*b, a cross b = a dot [b]
	a outer b # outer product, defined like a outer b = a*transpose(b)
    a + b, a - b # addition, subtraction
    let name = a in expression # scoped dependent variable
*/

/* eg: Nape's DistanceJoint

	body body1, body2
	vector anchor1, anchor2
	scalar jointMin, jointMax

	limit jointMin 0 jointMax

	constraint 
		let r1 = relative body1.rotation anchor1 in
		let r2 = relative body2.rotation anchor2 in
		| (body2.position + r2) - (body1.position + r1) |

	limit constraint jointMin jointMax
*/

/* eg: Nape's LineJoint

	body body1, body2
	vector anchor1, anchor2, direction
	scalar jointMin, jointMax

	limit jointMin (-inf) jointMax
	limit | direction | eps inf

	constraint 
		let r1 = relative body1.rotation anchor1 in
		let r2 = relative body2.rotation anchor2 in
		let dir = unit (relative body1.rotation direction) in
		let del = (body2.position + r2) - (body1.position + r1) in
		{ del dot dir
		  del cross dir }

	limit constraint { jointMin 0 } { jointMax 0 }
*/

enum Atom {
	aBodies(names:Array<String>);
	aVariables(vars:Array<{name:String,type:EType,def:Expr,del:Expr}>);
	aLimit(expr:Expr,lower:Expr,upper:Expr); //expr=null denotes constraint
	aConstraint(expr:Expr);
}

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
	static var constrP   =withSpacing("constraint".identifier());
	static var limitP    = withSpacing("limit".identifier());

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
			def  <= ParserM.dO({
				equalsP;
				e <= exprP;
				ret(e);
			}).option();
			del  <= ParserM.dO({
				delP;
				e <= exprP;
				ret(e);
			}).option();
			ret({ name: name, type: type,
				  del: switch(del) { case Some(x): x; default: null; },
				  def: switch(def) { case Some(x): x; default: null; }
			});
		}), commaP);
		ret(aVariables(decls));
	}).tag("variable declaration");

	static var bodydeclP = ParserM.dO({
		bodyP;
		names <= plussep(ParserM.dO({
			name <= identP;
			ret(name);
		}), commaP);
		ret(aBodies(names));
	}).tag("body declaration");

	static var limitdeclP = ParserM.dO({
		limitP;
		e <= ParserM.dO({ constrP; ret(null); }).or(ParserM.dO({ e <= exprP; ret(e); }));
		lower <= exprP;
		upper <= exprP;
		ret(aLimit(e,lower,upper));
	}).tag("limit declaration");

	static var constraintdeclP = ParserM.dO({
		constrP;
		e <= exprP;
		ret(aConstraint(e));
	}).tag("constraint declaration");

	static var declarationsP = [vardeclP, bodydeclP, limitdeclP, constraintdeclP].ors();

	//--------------------------------------------------------
	//expression

	// ( expr ), | expr |, [ expr ], value, variable
	static var expr0P = [
		ParserM.dO({ lParP; e <= exprP; rParP; ret(e); }),
		ParserM.dO({ lSquareP; e <= exprP; rSquareP; ret(ePerp(e)); }),
		valueP,
		ParserM.dO({ n <= identP; ret(eVariable(n)); }),
		ParserM.dO({ magP; e <= exprP; magP; ret(eMag(e)); }),
		ParserM.dO({ subP; e <= exprP; ret(eMul(eScalar(-1),e)); })
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

	static var constraintP = declarationsP.many().memo();

	//--------------------------------------------------------

	public static function parse(constraint:String):Array<Atom> {
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
