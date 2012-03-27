package symbolic;

enum Expr {
	eScalar(x:Float);
	eVector(x:Float,y:Float);
	eMatrix(a:Float,b:Float,c:Float,d:Float);

	eRelative(rot:String,x:Expr);	

	eVariable(n:String);
	eLet(n:String,equals:Expr,within:Expr);

	eAdd(x:Expr,y:Expr); 
	eMul(x:Expr,y:Expr);
	eDot(x:Expr,y:Expr);
	eCross(x:Expr,y:Expr);
	ePerp(x:Expr);
	eOuter(x:Expr,y:Expr);
	eMag(x:Expr);
	eInv(x:Expr);
	eUnit(x:Expr);
}

enum EType {
	etScalar;
	etColVector;
	etRowVector;
	etMatrix;
}

typedef Context = {
	env  : Hash<Array<Expr>>, //let's
	vars : Hash<{type:EType,del:Expr}> //vars
};

//-----------------------------------------------------------

class ExprUtils {
	static public function emptyContext() {
		return { env: new Hash<Array<Expr>>(), vars : new Hash<{type:EType,del:Expr}>() };
	}
	static public function variableContext(context:Context,n:String,type:EType,?del:Expr) {
		if(del==null) {
			del = switch(type) {
			case etScalar: eScalar(0);
			case etColVector: eVector(0,0);
			case etRowVector: ePerp(eVector(0,0));
			case etMatrix: eMatrix(0,0,0,0);
			}
		}
		context.vars.set(n, {type:type,del:del});
	}
	static public function variableRedact(context:Context,n:String) {
		context.vars.remove(n);
	}
	static public function extendContext(context:Context,n:String,eq:Expr) {
		if(!context.env.exists(n)) context.env.set(n, [eq]);
		else context.env.get(n).unshift(eq);
	}
	static public function redactContext(context:Context,n:String) {
		var env = context.env.get(n);
		env.shift();
		if(env.length==0) context.env.remove(n);
	}

	//----------------------------------------------------------------------------
	//===========================================================================

	//printing algorithm
	static public function print_type(e:EType) {
		return switch(e) {
			case etScalar: "scalar";
			case etColVector: "col-vector";
			case etRowVector: "row-vector";
			case etMatrix: "matrix";
		}
	}
	static public function print_context(c:Context) {
		var ret = "";
		for(n in c.vars.keys()) {
			var v = c.vars.get(n);
			ret += n+":"+print_type(v.type)+" -> "+print(v.del)+"\n";
		}
		for(n in c.env.keys()) {
			var let = c.env.get(n);
			ret += "n <- [";
			var fst = true;
			for(e in let) {
				if(!fst) ret += ",";
				fst = false;
				ret += print(e);
			}
			ret += "]\n";
		}
		return ret;
	}
	static public function print(e:Expr) {
		return switch(e) {
			case eScalar(x): Std.string(x);
			case eVector(x,y): "vec("+Std.string(x)+","+Std.string(y)+")";
			case eMatrix(a,b,c,d): "mat("+Std.string(a)+","+Std.string(b)+","+Std.string(c)+","+Std.string(d)+")";
			case eRelative(rot,x): "rel("+rot+" of "+print(x)+")";

			case eVariable(n): "var("+n+")";
			case eLet(n,eq,of): "let "+n+"="+print(eq)+" in\n   "+print(of);
	
			case eAdd(x,y): "("+print(x)+"+"+print(y)+")";
			case eMul(x,y): "("+print(x)+"*"+print(y)+")";
			case eDot(x,y): "("+print(x)+" dot "+print(y)+")";
			case eCross(x,y): "("+print(x)+" x "+print(y)+")";
			case ePerp(x): "perp("+print(x)+")";
			case eOuter(x,y): "outer("+print(x)+","+print(y)+")";
			case eMag(x): "mag("+print(x)+")";
			case eInv(x): "inv("+print(x)+")";
			case eUnit(x): "unit("+print(x)+")";
		}
	}

	//----------------------------------------------------------------------------
	//===========================================================================

	//typing algorithm
	static public function etype(e:Expr,?context:Context) {
		if(context==null) context = emptyContext();

		return switch(e) {
			case eScalar(_): etScalar;
			case eVector(_,_): etColVector;
			case eMatrix(_,_,_,_): etMatrix;
			case eRelative(_,_): etColVector;
	
			case eVariable(n): 
				if(context.env.exists(n))
					 etype(context.env.get(n)[0],context);
				else context.vars.get(n).type;
			case eLet(n,eq,within):
				extendContext(context, n,eq);
				var ret = etype(within,context);
				redactContext(context, n);
				ret;

			case eAdd(x,y): etype(x,context);
			case eMul(x,y):
				var xt = etype(x,context);
				var yt = etype(y,context);
				switch(xt) {
				case etScalar: yt;
				case etRowVector:
					switch(yt) {
					case etScalar: etRowVector;
					case etColVector: etScalar;
					case etMatrix: etRowVector;
					default: null;
					}
				case etColVector:
					switch(yt) {
					case etScalar: etColVector;
					case etRowVector: etMatrix;
					default: null;
					}
				case etMatrix:
					switch(yt) {
					case etScalar: etMatrix;
					case etColVector: etColVector;
					case etMatrix: etMatrix;
					default: null;
					}
				}
			case eDot(x,y): etScalar;
			case eCross(x,y):
				var xt = etype(x,context);
				var yt = etype(y,context);
				switch(xt) {
				case etScalar: etColVector;
				case etColVector:
					switch(yt) {
						case etColVector: etScalar;
						case etScalar: etColVector;
						default: null;
					}
				default: null;
				}
			case ePerp(x):
				switch(etype(x,context)) {
				case etScalar: etScalar;
				case etRowVector: etColVector;
				case etColVector: etRowVector;
				default: null;
				}
			case eOuter(x,y):
				switch(etype(x,context)) {
				case etScalar: etScalar;
				default: etMatrix;
				}
			case eMag(x): etScalar;
			case eInv(x): etScalar;
			case eUnit(x): etype(x,context);
		}
	}

	//----------------------------------------------------------------------------
	//===========================================================================

	//evaluator
	public static function eval(e:Expr,context:Context) {
		return switch(e) {
			default: e;
			case eRelative(rot,x):
				eRelative(rot,eval(x,context)); //meh

			case eVariable(n):
				eval(context.env.get(n)[0],context);
			case eLet(n,eq,vin):
				extendContext(context, n,eval(eq,context));
				var ret = eval(vin,context);
				redactContext(context, n);
				ret;
			
			case eAdd(inx,iny):
				var x = eval(inx,context);
				var y = eval(iny,context);
				switch(x) {
				case eScalar(x): switch(y) { case eScalar(y): eScalar(x+y); default: null; }
				case eVector(x1,x2): switch(y) { case eVector(y1,y2): eVector(x1+y1,x2+y2); default: null; }
				case eMatrix(xa,xb,xc,xd): switch(y) { case eMatrix(ya,yb,yc,yd): eMatrix(xa+ya,xb+yb,xc+yc,xd+yd); default: null; }
				case ePerp(x): switch(y) { case ePerp(y): eval(ePerp(eAdd(x,y)),context); default: null; }
				default: null;
				}

			case eDot(inx,iny):
				var x = eval(inx,context);
				var y = eval(iny,context);
				switch(x) {
				case eScalar(x): switch(y) { case eScalar(y): eScalar(x*y); default: null; }
				case eVector(x1,x2): switch(y) { case eVector(y1,y2): eScalar(x1*y1+x2*y2); default: null; }
				default:null;
				}

			case eCross(inx,iny):
				var x = eval(inx,context);
				var y = eval(iny,context);
				switch(x) {
				case eScalar(x): switch(y) { case eVector(y1,y2): eVector(-y2*x,y1*x); default: null; }
				case eVector(x1,x2): switch(y) {
					case eVector(y1,y2): eScalar(x1*y2-x2*y1);
					case eScalar(y): eVector(x2*y,-x1*y);
					default: null;
				}
				default: null;	
				}
		}	
	}

	//----------------------------------------------------------------------------
	//===========================================================================

	//derivatives
/*	public static function diff(e:Expr,context:Context,?wrt:String,?elt=-1) {
		function _diff(e:Expr) return diff(e,context,wrt,elt);

		return switch(e) {
			case eScalar(_): eScalar(0);
			case eVector(_,_): eVector(0,0);
			case eMatrix(_,_,_,_): eMatrix(0,0,0,0);
			case eRelative(rot,x):
				if(wrt==null) eCross(eVariable(rot),x);
				else eVector(0,0);
			
			case eVariable(n):
				var vart = context.vars.get(n);
					switch(vart.type) {
					case etScalar:
						if(wrt==n) eScalar(1);
						else if(wrt==null) vart.del;
						else eScalar(0);
					case etColVector:
						if(wrt==n) eVector(elt==0?1:0,elt==1?1:0);
						else if(wrt==null) vart.del;
						else eVector(0,0);
					default: null;
				}
			case eLet(n,eq,vin):
				
				context.variableContext(n+"__prime",	
		}
	}*/
}
