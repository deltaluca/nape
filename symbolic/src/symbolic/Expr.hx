package symbolic;

using Lambda;

enum Expr {
	eScalar(x:Float);
	eRowVector(x:Float,y:Float);
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

	eBlock(xs:Array<Expr>);
}

enum EType {
	etScalar;
	etVector;
	etMatrix;
	etBlock(xs:Array<EType>);
	etRowVector;
}

typedef Context = {
	env  : Hash<Array<Expr>>, //let's
	vars : Hash<{type:EType,del:Expr,let:Bool}> //vars
};

//-----------------------------------------------------------

class ExprUtils {
	static public function emptyContext() {
		return { env: new Hash<Array<Expr>>(), vars : new Hash<{type:EType,del:Expr,let:Bool}>() };
	}
	static public function variableContext(context:Context,n:String,type:EType,?del:Expr,?let=false) {
		if(del==null) {
			del = switch(type) {
			case etScalar: eScalar(0);
			case etVector: eVector(0,0);
			case etRowVector: eRowVector(0,0);
			case etMatrix: eMatrix(0,0,0,0);
			default: null;
			}
		}
		context.vars.set(n, {type:type,del:del,let:let});
	}
	static public inline function variableRedact(context:Context,n:String) {
		context.vars.remove(n);
	}
	static public inline function extendContext(context:Context,n:String,eq:Expr) {
		var env = context.env.get(n);
		if(env==null) context.env.set(n, [eq]);
		else env.unshift(eq);
	}
	static public inline function redactContext(context:Context,n:String) {
		var env = context.env.get(n);
		env.shift();
		if(env.length==0) context.env.remove(n);
	}
	static public inline function replaceContext(context:Context,n:String,eq:Expr) {
		var env = context.env.get(n);
		if(env==null) context.env.set(n, [eq]);
		else env[0] = eq;
	}

	static public inline function map<T,S>(xs:Array<T>,f:T->S):Array<S> {
		var ret = [];
		for(x in xs) ret.push(f(x));
		return ret;
	}
	static public inline function zipWith<T,S,R>(xs:Array<T>,ys:Array<S>,f:T->S->R):Array<R> {
		var ret = [];
		for(i in 0...(xs.length<ys.length ? xs.length : ys.length))
			ret.push(f(xs[i],ys[i]));
		return ret;
	}

	//---------------------------------------------------------------------------
	//===========================================================================

	//printing algorithm
	static public function print_type(e:EType) {
		if(e==null) return "!!null-type!!";
		return switch(e) {
			case etScalar: "scalar";
			case etVector: "vector";
			case etRowVector: "rowvector";
			case etMatrix: "matrix";
			case etBlock(xs):
				var ret = "{";
				var fst = true;
				for(x in xs) { if(!fst) ret += " "; fst = false; ret += print_type(x); }
				ret += "}";
				ret;
		}
	}
	static public function print_context(c:Context) {
		if(c==null) return "!!null-context!!";
		var ret = "";
		for(n in c.vars.keys()) {
			var v = c.vars.get(n);
			ret += print_type(v.type)+" "+n+" -> "+print(v.del)+"\n";
		}
		for(n in c.env.keys()) {
			var let = c.env.get(n);
			ret += n+" <- ";
			var fst = true;
			for(e in let) {
				if(!fst) ret += " ~ ";
				fst = false;
				ret += print(e);
			}
			ret += "\n";
		}
		return ret;
	}
	static public function print(e:Expr) {
		if(e==null) return "!!null-expression!!";
		return switch(e) {
			case eScalar(x): Std.string(x);
			case eVector(x,y): "["+Std.string(x)+" "+Std.string(y)+"]";
			case eRowVector(x,y): "["+Std.string(x)+" ; "+Std.string(y)+"]";
			case eMatrix(a,b,c,d): "["+Std.string(a)+" "+Std.string(b)+" ; "+Std.string(c)+" "+Std.string(d)+"]";
			case eRelative(rot,x): "(relative "+rot+" "+print(x)+")";

			case eVariable(n): n;
			case eLet(n,eq,of): "let "+n+"="+print(eq)+" in\n"+print(of);
	
			case eAdd(x,y): "("+print(x)+"+"+print(y)+")";
			case eMul(x,y): "("+print(x)+"*"+print(y)+")";
			case eDot(x,y): "("+print(x)+" dot "+print(y)+")";
			case eCross(x,y): "("+print(x)+" cross "+print(y)+")";
			case ePerp(x): "["+print(x)+"]";
			case eOuter(x,y): "("+print(x)+" outer "+print(y)+")";
			case eMag(x): "|"+print(x)+"|";
			case eInv(x): "(1/"+print(x)+")";
			case eUnit(x): "(unit "+print(x)+")";

			case eBlock(xs): 
				var ret = "{";
				var fst = true;
				for(x in xs) { if(!fst) ret += "\n"; fst = false; ret += print(x); }
				ret += "}";
				ret;
		}
	}

	//----------------------------------------------------------------------------
	//===========================================================================

	//typing algorithm
	static public function etype(e:Expr,context:Context) {
		return switch(e) {
			case eScalar(_): etScalar;
			case eVector(_,_): etVector;
			case eRowVector(_,_): etRowVector;
			case eMatrix(_,_,_,_): etMatrix;
			case eRelative(_,_): etVector;
	
			case eVariable(n): 
				if(context.env.exists(n))
					 etype(context.env.get(n)[0],context);
				else {
					if(!context.vars.exists(n)) throw "TypeError: Variable '"+n+"' has no type in context";
					context.vars.get(n).type;
				}
			case eLet(n,eq,within):
				extendContext(context, n,eq);
				var ret:EType = null;
				try {
					ret = etype(within,context);
				}catch(e:Dynamic) {}
				redactContext(context, n);
				ret;

			case eAdd(x,y): etype(x,context);
			case eMul(x,y):
				function eMulType(xt,yt) {
					return switch(xt) {
					case etBlock(xs): etBlock(map(xs, function(x) return eMulType(x,yt)));
					case etScalar: yt;
					case etRowVector:
						switch(yt) {
						case etBlock(ys): etBlock(map(ys, function(y) return eMulType(xt,y)));
						case etScalar: etRowVector;
						case etVector: etScalar;
						case etMatrix: etRowVector;
						default: throw "TypeError: Cannot muliply row-vector with row-vector"; null;
						}
					case etVector:
						switch(yt) {
						case etBlock(ys): etBlock(map(ys, function(y) return eMulType(xt,y)));
						case etScalar: etVector;
						case etRowVector: etMatrix;
						default: throw "TypeError: Cannot mulyiple vector with matrix or vector"; null;
						}
					case etMatrix:
						switch(yt) {
						case etBlock(ys): etBlock(map(ys, function(y) return eMulType(xt,y)));
						case etScalar: etMatrix;
						case etVector: etVector;
						case etMatrix: etMatrix;
						default: throw "TypeError: Cannot multiply matrix with row-vector"; null;
						}
					default: null;
					}
				}
				eMulType(etype(x,context),etype(y,context));
			case eDot(x,y): 
				switch(etype(x,context)) { case etRowVector: etMatrix; default: etScalar; } //improve TODO
			case eCross(x,y):
				var xt = etype(x,context);
				var yt = etype(y,context);
				switch(xt) {
				case etScalar: etVector;
				case etVector:
					switch(yt) {
						case etVector: etScalar;
						case etScalar: etVector;
						default: throw "TypeError: Cannot cross vector with matrix/row-vector/block expression"; null;
					}
				default: throw "TypeError: Cannot cross matrix/row-vector/block expression with T"; null;
				}
			case ePerp(x):
				switch(etype(x,context)) {
				case etScalar: etScalar;
				case etVector: etVector;
				case etRowVector: etRowVector;
				case etBlock(xs): etBlock(xs); //should be made better TODO
				default: throw "TypeError: Cannot produce perp of matrix"; null;
				}
			case eOuter(x,y):
				function eOuterType(xt,yt) {
					return switch(xt) {
					case etBlock(xs): etBlock(map(xs, function(x) return eOuterType(x,yt)));
					case etScalar:
						switch(yt) {
						case etBlock(ys): etBlock(map(ys, function(y) return eOuterType(xt,y)));
						case etScalar: etScalar;
						case etVector: etRowVector;
						case etRowVector: etVector;	
						default: throw "TypeError: Cannot produce outerproduct of scalar with matrix"; null;
						}
					case etVector:
						switch(yt) {
						case etBlock(ys): etBlock(map(ys, function(y) return eOuterType(xt,y)));
						case etScalar: etVector;
						case etVector: etMatrix;
						default: throw "TypeError: Cannot produce outerproduct of vector with row-vector/matrix"; null;
						}
					case etRowVector:
						switch(yt) {
						case etBlock(ys): etBlock(map(ys, function(y) return eOuterType(xt,y)));
						case etScalar: etRowVector;
						case etRowVector: etScalar;
						default: throw "TypeError: Cannot produce outerproduct of row-vector with matrix/vector"; null;
						}
					default: throw "TypeError: Cannot produce outerproduct of matrix with T"; null;
					}
				}
				eOuterType(etype(x,context),etype(y,context));
			case eMag(x): etScalar;
			case eInv(x): etScalar;
			case eUnit(x): etype(x,context);

			case eBlock(xs): etBlock(map(xs,function (y) return etype(y,context)));
		}
	}

	//----------------------------------------------------------------------------
	//===========================================================================

	//evaluator
	public static inline function tryeval(e:Expr,context:Context) {
		try {
			var t = eval(e,context);
			if(t!=null) e = t;
		}catch(e:Dynamic) {
		}
		return e;
	}

	public static function eval(e:Expr,context:Context) {
		return switch(e) {
			default: e;
			case eRelative(rot,ix):
				var x = eval(ix,context);
				var r = eval(eVariable(rot),context);
				switch(r) {
				case eScalar(r): switch(x) { case eVector(x,y):
					eVector(Math.cos(r)*x-Math.sin(r)*y,Math.sin(r)*x+Math.cos(r)*y);
				  default: throw "Error: eRelative(_,x!=eVector)"; null;
				} default: throw "Error: eRelative(r!=eScalar,_)"; null; }

			case eVariable(n):
				if(!context.env.exists(n)) { throw "Error: No variable exists in eval() for n="+n; null; }
				else eval(context.env.get(n)[0],context);
			case eLet(n,eq,vin):
				extendContext(context, n,eval(eq,context));
				var ret:Expr = null;
				var err:Dynamic = null;
				try {
					ret = eval(vin,context);
				}catch(e:Dynamic) { err = e; }
				redactContext(context, n);
				if(err!=null) throw err;
				ret;
			
			case eAdd(inx,iny):
				var x = eval(inx,context);
				var y = eval(iny,context);
				switch(x) {
				case eScalar(x): switch(y) { case eScalar(y): eScalar(x+y); default: throw "Error: eAdd(eScalar,¬eScalar)"; null; }
				case eVector(x1,x2): switch(y) { case eVector(y1,y2): eVector(x1+y1,x2+y2); default: throw "Error: eAdd(eVector,¬eVector)"; null; }
				case eMatrix(xa,xb,xc,xd): switch(y) { case eMatrix(ya,yb,yc,yd): eMatrix(xa+ya,xb+yb,xc+yc,xd+yd); default: throw "Error: eAdd(eMatrix,¬eMatrix)"; null; }
				case eBlock(xs): switch(y) { case eBlock(ys): eBlock(zipWith(xs,ys, function (x,y) return eval(eAdd(x,y),context))); default: throw "Error: eAdd(eBlock,¬eBlock)"; null; }
				case eRowVector(x1,x2): switch(y) { case eRowVector(y1,y2): eRowVector(x1+y1,x2+y2); default: throw "Error: eAdd(eRowVector,¬eRowVector)"; null; }
				default: throw "Error: eAdd(x!=value,_) with inx="+Std.string(inx)+" and x="+Std.string(x); null;
				}
			
			case eMul(inx,iny):
				var x = eval(inx,context);
				var y = eval(iny,context);
				switch(x) {
				case eScalar(xi):
					switch(y) {
					case eScalar(y): eScalar(xi*y);
					case eVector(y1,y2): eVector(xi*y1,xi*y2);
					case eRowVector(y1,y2): eRowVector(xi*y1,xi*y2);
					case eMatrix(a,b,c,d): eMatrix(xi*a,xi*b,xi*c,xi*d);
					case eBlock(ys): eBlock(map(ys, function(y) return eval(eMul(x,y),context)));
					default: throw "Error: eMul(x=eScalar,y!=value)"; null;
					}
				case eVector(x1,x2):
					switch(y) {
					case eScalar(y): eVector(y*x1,y*x2);
					case eRowVector(y1,y2): eMatrix(x1*y1,x1*y2,x2*y1,x2*y2);
					case eBlock(ys): eBlock(map(ys, function(y) return eval(eMul(x,y),context)));
					default: throw "Error: eMul(x=eVector,y!=value)"; null;
					}
				case eRowVector(x1,x2):
					switch(y) {
					case eScalar(y): eRowVector(x1*y,x2*y);
					case eVector(y1,y2): eScalar(x1*y1+x2*y2);
					case eMatrix(a,b,c,d): eRowVector(x1*a+x2*c,x1*b+x2*d);
					case eBlock(ys): eBlock(map(ys, function(y) return eval(eMul(x,y),context)));
					default: throw "Error: eMul(x=eRowVector,y!=value)"; null;
					}
				case eMatrix(a,b,c,d):
					switch(y) {
					case eScalar(y): eMatrix(a*y,b*y,c*y,d*y);
					case eVector(y1,y2): eVector(a*y1+b*y2,c*y1+d*y2);
					case eBlock(ys): eBlock(map(ys, function(y) return eval(eMul(x,y),context)));
					default: throw "Error: eMul(x=eMatrix,y!=value)"; null;
					}
				case eBlock(xs): eBlock(map(xs, function(x) return eval(eMul(x,y),context)));
				default: throw "Error: eMul(x!=value,_)"; null;
				}

			case eDot(inx,iny):
				var x = eval(inx,context);
				var y = eval(iny,context);
				switch(x) {
				case eScalar(x): switch(y) { case eScalar(y): eScalar(x*y); default: throw "Error: eDot(eScalar,¬eScalar)"; null; }
				case eVector(x1,x2): switch(y) { case eVector(y1,y2): eScalar(x1*y1+x2*y2); default: throw "Error: eDot(eVector,¬eVector)"; null; }
				case eRowVector(x1,x2): switch(y) { case eRowVector(y1,y2): eMatrix(x1*y1,x1*y2,x2*y1,x2*y2); default: throw "Error: eDot(eRowVector,¬eRowVector)"; null; }
				default: throw "Error: eDot(x=matrix/block/non-value,_)"; null;
				}

			case eCross(inx,iny):
				var x = eval(inx,context);
				var y = eval(iny,context);
				switch(x) {
				case eScalar(x): switch(y) { case eVector(y1,y2): eVector(-y2*x,y1*x); default: throw "Error: eCross(eScalar,¬eVector)"; null; }
				case eVector(x1,x2): switch(y) {
					case eVector(y1,y2): eScalar(x1*y2-x2*y1);
					case eScalar(y): eVector(x2*y,-x1*y);
					default: throw "Error: eCross(eVector,!(eVector|eScalar))"; null;
				}
				default: throw "Error: eCross(¬(eVector|eScalar))"; null;	
				}
			case ePerp(inx):
				var x = eval(inx,context);
				switch(x) {
				case eVector(x,y): eVector(-y,x);
				case eRowVector(x,y): eRowVector(-y,x);
				default: throw "Error: ePerp(¬vector-type)"; null;
				}
			case eOuter(inx,iny):
				var x = eval(inx,context);
				var y = eval(iny,context);
				switch(x) {
				case eScalar(xi):
					switch(y) {
					case eScalar(y): eScalar(xi*y);
					case eVector(y1,y2): eRowVector(xi*y1,xi*y2);
					case eRowVector(y1,y2): eVector(xi*y1,xi*y2);
					case eBlock(ys): eBlock(map(ys, function(y) return eval(eOuter(x,y),context)));
					default: throw "Error: eOuter(eScalar,¬scalar/vector-type/block)"; null;
					}
				case eVector(x1,x2):
					switch(y) {
					case eScalar(y): eVector(y*x1,y*x2);
					case eVector(y1,y2): eMatrix(x1*y1,x1*y2,x2*y1,x2*y2);
					case eBlock(ys): eBlock(map(ys, function(y) return eval(eOuter(x,y),context)));
					default: throw "Error: eOuter(eVector,¬scalar|vector|block"; null;
					}
				case eRowVector(x1,x2):
					switch(y) {
					case eScalar(y): eRowVector(y*x1,y*x2);
					case eRowVector(y1,y2): eScalar(x1*y1+x2*y2);
					case eBlock(ys): eBlock(map(ys, function(y) return eval(eOuter(x,y),context)));
					default: throw "Error: eOuter(eRowVector,¬scalar|row-vector|block"; null;
					}
				case eBlock(xs): eBlock(map(xs, function(x) return eval(eOuter(x,y),context)));
				default: throw "Error: eOuter(¬scalar/vector/block-type)"; null;
				}
			case eMag(inx):
				var x = eval(inx,context);
				switch(x) {
				case eScalar(x): eScalar(Math.abs(x));
				case eVector(x,y): eScalar(Math.sqrt(x*x+y*y));
				case eRowVector(x,y): eScalar(Math.sqrt(x*x+y*y));
				default: throw "Error: eMag(¬scalar/vector-type)"; null;
				}	
			case eInv(inx):
				var x = eval(inx,context);
				switch(x) {
				case eScalar(x): eScalar(1/x);
				default: throw "Error: eInv(¬scalar)"; null;
				}
			case eUnit(inx):
				var x = eval(inx,context);
				switch(x) {
				case eScalar(x): eScalar(x == 0 ? 0 : x > 0 ? 1 : -1);
				case eVector(x,y): var mag = 1/Math.sqrt(x*x+y*y); eVector(x*mag,y*mag);
				case eRowVector(x,y): var mag = 1/Math.sqrt(x*x+y*y); eRowVector(x*mag,y*mag);
				default: throw "Error: eUnit(¬scalar/vector-type)"; null;
				}

			case eBlock(inx):
				var x = map(inx, function (y) return eval(y,context));
				var ret = eBlock(x);
				for(xi in x) if(xi==null) ret = null;
				ret;
		}	
	}

	//---------------------------------------------------------------------------
	//===========================================================================

	//simplification
	public static function simple(e:Expr,context:Context) {
		return __simple(e,context);
	}
	static function __simple(e:Expr,context:Context) {
		function _simple(e:Expr) return tryeval(simple(e,context),context);
		function zero(e:Expr) {
			return switch(e) {
				case eScalar(x): x==0;
				case eVector(x,y): x==y && y==0;
				case eRowVector(x,y): x==y && y==0;
				case eMatrix(x,y,z,w): x==y && y==z && z==w && w==0;
				case eBlock(xs): !Lambda.exists(xs, function(x) return !zero(x));
				default: false;
			}
		}
		function zerotype(e:EType) {
			return switch(e) {
				case etScalar: eScalar(0);
				case etVector: eVector(0,0);
				case etRowVector: eRowVector(0,0);
				case etMatrix: eMatrix(0,0,0,0);
				case etBlock(xs): eBlock(map(xs,zerotype));
			}
		}
		function one(e:Expr,?val=1.0) {
			return switch(e) {
				case eScalar(x): x==val;
				case eMatrix(x,y,z,w): x==w && x==val && y==z && z==0;
				default: false;
			}
		}

		function countof(e:Expr,on:String) {
			return switch(e) {
				default: 0;
				case eVariable(n): n==on ? 1 : 0;
				case eRelative(rot,x): (rot==on ? 1 : 0) + countof(x,on);
				case eLet(_,equals,within): countof(equals,on) + countof(within,on);
				case eAdd(a,b): countof(a,on) + countof(b,on);
				case eMul(a,b): countof(a,on) + countof(b,on);	
				case eCross(a,b): countof(a,on) + countof(b,on);	
				case eDot(a,b): countof(a,on) + countof(b,on);	
				case eOuter(a,b): countof(a,on) + countof(b,on);	
				case eMag(a): countof(a,on);
				case eInv(a): countof(a,on);
				case eUnit(a): countof(a,on);
				case ePerp(a): countof(a,on);
				case eBlock(xs): 
					var c = 0;
					for(x in xs) c += countof(x,on);
					c;
			}
		}
		function depends(e:Expr,on:String) return countof(e,on)!=0;
		function substitute(e:Expr,on:String,rep:Expr) {
			function sub(e:Expr) return substitute(e,on,rep);
			return switch(e) {
				default: e;
				case eVariable(n): n==on ? rep : e;
				case eRelative(rot,x): eRelative(rot,sub(x));
				case eLet(n,equals,within): eLet(n,sub(equals),sub(within));
				case eAdd(a,b): eAdd(sub(a),sub(b));
				case eMul(a,b): eMul(sub(a),sub(b));
				case eCross(a,b): eCross(sub(a),sub(b));
				case eDot(a,b): eDot(sub(a),sub(b));
				case eOuter(a,b): eOuter(sub(a),sub(b));
				case eMag(a): eMag(sub(a));
				case eInv(a): eInv(sub(a));
				case eUnit(a): eUnit(sub(a));
				case ePerp(a): ePerp(sub(a));
				case eBlock(xs): eBlock(map(xs,sub));
			}
		}

		var ret = switch(e) {
			default: e;
			case eRelative(rot,inx): eRelative(rot,_simple(inx));
			case eLet(n,ineq,invin):
				var eq = _simple(ineq);
				extendContext(context,n,eq);
				var vin = null;
				try {
					vin = tryeval(simple(invin,context),context);
				}catch(e:Dynamic) {}
				redactContext(context,n);

				var count = countof(vin,n);
				if(count==0) vin else if(count==1) substitute(vin,n,eq) else eLet(n,eq,vin);
			case eAdd(inx,iny):
				var x = _simple(inx);
				var y = _simple(iny);
				if(zero(x)) y else if(zero(y)) x
				else {
					var ret = 
					switch(x) { case eBlock(xs):
					switch(y) { case eBlock(ys):
						eBlock(zipWith(xs,ys,function (x,y) return eAdd(x,y)));
					default: null; }
					default: null; }
					ret == null ? eAdd(x,y) : ret;
				}
			case eMul(inx,iny):
				var x = _simple(inx);
				var y = _simple(iny);
				if(zero(x) || zero(y)) zerotype(etype(eMul(x,y),context))
				else if(one(x)) y else if(one(y)) x
				else {
					switch(x) {
					case eBlock(xs): _simple(eBlock(map(xs, function(x) return eMul(x,y))));
					default:
					switch(y) {
					case eBlock(ys): _simple(eBlock(map(ys, function(y) return eMul(x,y))));
					default: eMul(x,y);
					}}
				}
			case eDot(inx,iny):
				var x = _simple(inx);
				var y = _simple(iny);
				if(zero(x) || zero(y)) zerotype(etype(eDot(x,y),context))
				else eDot(x,y);
			case eCross(inx,iny):
				var x = _simple(inx);
				var y = _simple(iny);
				if(zero(x) || zero(y)) zerotype(etype(eCross(x,y),context))
				else if(one(x)) ePerp(y)
				else if(Type.enumEq(etype(x,context),etScalar))
					 eMul(x,ePerp(y))
				else if(Type.enumEq(etype(y,context),etScalar))
					 eMul(eMul(y,eScalar(-1)),ePerp(x));
				else eCross(x,y);
			case eOuter(inx,iny):
				var x = _simple(inx);
				var y = _simple(iny);
				if(zero(x) || zero(y)) zerotype(etype(eOuter(x,y),context))
				else {
					switch(x) {
					case eBlock(xs): _simple(eBlock(map(xs, function(x) return eOuter(x,y))));
					default:
					switch(y) {
					case eBlock(ys): _simple(eBlock(map(ys, function(y) return eOuter(x,y))));
					default: eOuter(x,y);
					}}
				}
			case ePerp(inx):
				ePerp(_simple(inx));
			case eMag(inx):
				eMag(_simple(inx));
			case eInv(inx):
				eInv(_simple(inx));
			case eUnit(inx):
				eUnit(_simple(inx));
			case eBlock(inx):
				eBlock(map(inx,_simple));
		}
		return tryeval(ret,context);
	}

	//---------------------------------------------------------------------------
	//===========================================================================

	//derivatives
	static var unitcnt = 0;
	public static function diff(e:Expr,context:Context,?wrt:String,?elt=-1) {
		function _diff(e:Expr) return diff(e,context,wrt,elt);

		return simple(switch(e) {
			default: throw "cannot differentiate "+print(e); null;

			case eScalar(_): eScalar(0);
			case eVector(_,_): eVector(0,0);
			case eMatrix(_,_,_,_): eMatrix(0,0,0,0);
			case eRelative(rot,x):
				if(wrt==null) eCross(_diff(eVariable(rot)),eRelative(rot,x));
				else eVector(0,0);
			
			case eVariable(n):
				if(!context.vars.exists(n)) {
					if(!context.env.exists(n)) throw "Error: Cannot find variable '"+n+"'";
					var vart = etype(context.env.get(n)[0],context);
					switch(vart) {
						case etScalar: eScalar(0);
						case etVector: eVector(0,0);
						default: throw "cannot differentiate "+print(e); null;
					}
				}else {
					var vart = context.vars.get(n);
					if(vart.let) vart.del
					else {
						switch(vart.type) {
							case etScalar:
								if(wrt==n) eScalar(1);
								else if(wrt==null) vart.del;
								else eScalar(0);
							case etVector:
								if(wrt==n) eVector(elt==0?1:0,elt==1?1:0);
								else if(wrt==null) vart.del;
								else eVector(0,0);
							default: throw "cannot differentiate "+print(e); null;
						}
					}
				}
			case eLet(n,eq,vin):
				var eqd = _diff(eq);

				var prime = n+"'";
				if(wrt!=null) {
					prime += wrt;
					if(elt!=-1) prime += Std.string(elt);
				}

				variableContext(context,n,etype(eq,context),eVariable(prime),true);
				extendContext(context,prime,eqd);
				var ret = eLet(n,eq,eLet(prime,eqd,_diff(vin)));
				redactContext(context,prime);
				variableRedact(context,n);
				ret;

			case eAdd(x,y): eAdd(_diff(x),_diff(y));
			case eMul(x,y):
				var dx = _diff(x);
				var dy = _diff(y);
				eAdd(eMul(dx,y),eMul(x,dy)); 
			case eDot(x,y):
				var dx = _diff(x);
				var dy = _diff(y);
				eAdd(eDot(dx,y),eDot(x,dy));
			case eCross(x,y):
				var dx = _diff(x);
				var dy = _diff(y);
				eAdd(eCross(dx,y),eCross(x,dy));
			case ePerp(x): ePerp(_diff(x));
			case eOuter(x,y):
				var dx = _diff(x);
				var dy = _diff(y);
				eAdd(eOuter(dx,y),eOuter(x,dy));
			case eMag(x): eDot(eUnit(x),_diff(x));
			case eInv(x): eMul(eScalar(-1),eMul(eInv(eMul(x,x)),_diff(x)));
			case eUnit(x): 
				var unit = "unit__"+(unitcnt++);
				eLet(unit, eUnit(x), eMul(
					ePerp(eVariable(unit)),
					eMul(
						eCross(eVariable(unit),_diff(x)),
						eInv(eMag(x))
					)
				));
			case eBlock(xs):
				eBlock(map(xs,_diff));
		}, context);
	}
}
