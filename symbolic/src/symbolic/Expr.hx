package symbolic;

enum Expr {
	eScalar(x:Float);
	eVector(x:Float,y:Float);
	eMatrix(a:Float,b:Float,c:Float,d:Float);

	eRelative(rot:Expr,x:Expr);	

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
	static public function extendContext(context:Context,n:String,eq:Expr) {
		if(!context.env.exists(n)) context.env.set(n, [eq]);
		else context.env.get(n).unshift(eq);
	}
	static public function redactContext(context:Context,n:String) {
		var env = context.env.get(n);
		env.shift();
		if(env.length==0) context.env.remove(n);
	}

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
			case eRelative(row,x): "rel("+print(row)+" of "+print(x)+")";

			case eVariable(n): "var("+n+")";
			case eLet(n,eq,of): "let("+n+"="+print(eq)+") in "+print(of);
	
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
}
