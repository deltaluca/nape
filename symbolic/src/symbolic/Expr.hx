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
	etVector;
	etMatrix;
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
			case etMatrix: eMatrix(0,0,0,0);
			}
		}
		context.vars.set(n, {type:type,del:del,let:let});
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
			case etVector: "vector";
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
			case eVector(_,_): etVector;
			case eMatrix(_,_,_,_): etMatrix;
			case eRelative(_,_): etVector;
	
			case eVariable(n): 
				if(context.env.exists(n))
					 etype(context.env.get(n)[0],context);
				else context.vars.get(n).type;
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
				var xt = etype(x,context);
				var yt = etype(y,context);
				switch(xt) {
				case etScalar: yt;
				case etVector:
					switch(yt) {
					case etScalar: etVector;
					default: null;
					}
				case etMatrix:
					switch(yt) {
					case etScalar: etMatrix;
					case etVector: etVector;
					case etMatrix: etMatrix;
					default: null;
					}
				}
			case eDot(x,y): etScalar;
			case eCross(x,y):
				var xt = etype(x,context);
				var yt = etype(y,context);
				switch(xt) {
				case etScalar: etVector;
				case etVector:
					switch(yt) {
						case etVector: etScalar;
						case etScalar: etVector;
						default: null;
					}
				default: null;
				}
			case ePerp(x):
				switch(etype(x,context)) {
				case etScalar: etScalar;
				case etVector: etVector;
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
			case eRelative(rot,ix):
				var x = eval(ix,context);
				var r = eval(eVariable(rot),context);
				switch(r) {
				case eScalar(r): switch(x) { case eVector(x,y):
					eVector(Math.cos(r)*x-Math.sin(r)*y,Math.sin(r)*x+Math.cos(r)*y);
				  default: null;
				} default: null; }

			case eVariable(n):
				eval(context.env.get(n)[0],context);
			case eLet(n,eq,vin):
				extendContext(context, n,eval(eq,context));
				var ret:Expr = null;
				try {
					ret = eval(vin,context);
				}catch(e:Dynamic) {}
				redactContext(context, n);
				ret;
			
			case eAdd(inx,iny):
				var x = eval(inx,context);
				var y = eval(iny,context);
				switch(x) {
				case eScalar(x): switch(y) { case eScalar(y): eScalar(x+y); default: null; }
				case eVector(x1,x2): switch(y) { case eVector(y1,y2): eVector(x1+y1,x2+y2); default: null; }
				case eMatrix(xa,xb,xc,xd): switch(y) { case eMatrix(ya,yb,yc,yd): eMatrix(xa+ya,xb+yb,xc+yc,xd+yd); default: null; }
				default: null;
				}
			
			case eMul(inx,iny):
				var x = eval(inx,context);
				var y = eval(iny,context);
				switch(x) {
				case eScalar(x):
					switch(y) {
					case eScalar(y): eScalar(x*y);
					case eVector(y1,y2): eVector(x*y1,x*y2);
					case eMatrix(a,b,c,d): eMatrix(x*a,x*b,x*c,x*d);
					default: null;
					}
				case eVector(x1,x2):
					switch(y) {
					case eScalar(y): eVector(y*x1,y*x2);
					default: null;
					}
				case eMatrix(a,b,c,d):
					switch(y) {
					case eScalar(y): eMatrix(a*y,b*y,c*y,d*y);
					case eVector(y1,y2): eVector(a*y1+b*y2,c*y1+d*y2);
					default: null;
					}
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
			case ePerp(inx):
				var x = eval(inx,context);
				switch(x) {
				case eVector(x,y): eVector(-y,x);
				case ePerp(x): x;
				default: null;
				}
			case eOuter(inx,iny):
				var x = eval(inx,context);
				var y = eval(iny,context);
				switch(x) {
				case eScalar(x): switch(y) { case eScalar(y): eScalar(x*y); default: null; }
				case eVector(x1,x2): switch(y) { case eVector(y1,y2): eMatrix(x1*y1,x2*y1,x1*y2,x2*y2); default: null; }
				default: null;
				}
			case eMag(inx):
				var x = eval(inx,context);
				switch(x) {
				case eScalar(x): eScalar(Math.abs(x));
				case eVector(x,y): eScalar(Math.sqrt(x*x+y*y));
				default: null;
				}	
			case eInv(inx):
				var x = eval(inx,context);
				switch(x) {
				case eScalar(x): eScalar(1/x);
				default: null;
				}
			case eUnit(inx):
				var x = eval(inx,context);
				switch(x) {
				case eVector(x,y): var mag = 1/Math.sqrt(x*x+y*y); eVector(x*mag,y*mag);
				default: null;
				}
		}	
	}

	//---------------------------------------------------------------------------
	//===========================================================================

	//simplification
	public static function simple(e:Expr,context:Context) {
		return __simple(__simple(e,context),context);
	}
	static function __simple(e:Expr,context:Context) {
		function tryeval(e:Expr) {
			try {
				var t = eval(e,context);
				if(t!=null) e = t;
			}catch(e:Dynamic) {
			}
			return e;
		}
		function _simple(e:Expr) return tryeval(simple(e,context));
		function zero(e:Expr) {
			return switch(e) {
				case eScalar(x): x==0;
				case eVector(x,y): x==y && y==0;
				case eMatrix(x,y,z,w): x==y && y==z && z==w && w==1;
				default: false;
			}
		}
		function zerotype(e:EType) {
			return switch(e) {
				case etScalar: eScalar(0);
				case etVector: eVector(0,0);
				case etMatrix: eMatrix(0,0,0,0);
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
					vin = tryeval(simple(invin,context));
				}catch(e:Dynamic) {}
				redactContext(context,n);

				var count = countof(vin,n);
				if(count==0) vin else if(count==1) substitute(vin,n,eq) else eLet(n,eq,vin);
			case eAdd(inx,iny):
				var x = _simple(inx);
				var y = _simple(iny);
				if(zero(x)) y else if(zero(y)) x else eAdd(x,y);
			case eMul(inx,iny):
				var x = _simple(inx);
				var y = _simple(iny);
				if(zero(x) || zero(y)) zerotype(etype(eMul(x,y),context))
				else if(one(x)) y else if(one(y)) x
				else eMul(x,y);
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
				else eOuter(x,y);
			case ePerp(inx):
				ePerp(_simple(inx));
			case eMag(inx):
				eMag(_simple(inx));
			case eInv(inx):
				eInv(_simple(inx));
			case eUnit(inx):
				eUnit(_simple(inx));
		}
		return tryeval(ret);
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
				if(wrt==null) eCross(_diff(eVariable(rot)),x);
				else eVector(0,0);
			
			case eVariable(n):
				if(!context.vars.exists(n)) {
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

				var prime = n+"__diff";
				if(wrt!=null) {
					prime += wrt;
					if(elt!=-1) prime += "_"+Std.string(elt);
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
		}, context);
	}
}
