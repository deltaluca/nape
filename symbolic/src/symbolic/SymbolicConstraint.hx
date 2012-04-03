package symbolic;

import nape.constraint.UserConstraint;
import nape.geom.Vec2;
import nape.geom.Vec3;
import nape.phys.Body;

import symbolic.Expr;
import symbolic.Parser;

using symbolic.Expr.ExprUtils;

typedef ARRAY<T> = #if flash10 flash.Vector<T> #else Array<T> #end;

class SymbolicConstraint extends UserConstraint {

	#if flash @:protected #end private var context:Context;

	#if flash @:protected #end private var variables:Hash<{type:EType,value:Dynamic}>;
	#if flash @:protected #end private var bodies:Hash<Body>; //map body name to real body
	#if flash @:protected #end private var bindices:Array<String>; //map body index to body name
	#if flash @:protected #end private var limits:Array<{limit:Expr,lower:Expr,upper:Expr}>;

	#if flash @:protected #end private var posC:Expr;
	#if flash @:protected #end private var velC:Expr;
	#if flash @:protected #end private var J:Array<Expr>;
	#if flash @:protected #end private var effK:Expr;
	#if flash @:protected #end private var dim:Int;
	#if flash @:protected #end private var lower:Expr;
	#if flash @:protected #end private var upper:Expr;
	#if flash @:protected #end private var scale:Array<Float>;
	#if flash @:protected #end private var equal:Array<Bool>;

	//-----------------------------------------------------------------------------

	public function debug():String {
		var ret = "";
		ret += "# constraint context\n";
		ret += "# ------------------\n";
		ret += context.print_context()+"\n";
		ret += "# limits\n";
		ret += "# ------\n";
		for(l in limits) ret += "limit "+l.limit.print()+" "+l.lower.print()+" "+l.upper.print()+"\n";
		ret += "limit constraint "+(lower==null?"#def":lower.print())+" "+(upper==null?"#def":upper.print())+"\n";
		ret += "\n";
		ret += "# positional constraint\n";
		ret += "# ---------------------\n";
		ret += posC.print()+"\n";
		ret += "\n";
		ret += "# velocity constraint\n";
		ret += "# -------------------\n";
		ret += velC.print()+"\n";
		ret += "# jacobians\n";
		ret += "# ---------\n";
		for(j in J) ret += j.print()+"\n\n";
		ret += "# effective-mass matrix\n";
		ret += "# ---------------------\n";
		ret += effK.print();
		return ret;
	}

	//-----------------------------------------------------------------------------

	public function new(constraint:String) {
		var atoms = ConstraintParser.parse(constraint);
		context = ExprUtils.emptyContext();
		variables = new Hash<{type:EType,value:Dynamic}>();
		bodies = new Hash<Body>();
		limits = new Array<{limit:Expr,lower:Expr,upper:Expr}>();
		bindices = [];
	
		for(a in atoms) {
		switch(a) {
			case aVariables(vars):
				for(v in vars)
					context.variableContext(v.name, v.type, v.del);
			case aBodies(names):
				for(b in names) {
					bindices.push(b);
					context.variableContext(b+".position",etVector,eVariable(b+".velocity"));
					context.variableContext(b+".velocity",etVector);
					context.variableContext(b+".rotation",etScalar,eVariable(b+".angularVel"));
					context.variableContext(b+".angularVel",etScalar);
					context.variableContext(b+"#imass",etScalar);
					context.variableContext(b+"#iinertia",etScalar);
					bodies.set(b, null);
				}
			default:
		}}

		context.extendContext("inf",eScalar(Math.POSITIVE_INFINITY));
		context.extendContext("eps",eScalar(1e-10));

		for(a in atoms) {
		switch(a) {
			case aVariables(vars):
				for(v in vars) {
					var def:Dynamic = null;
					if(v.def==null) {
						switch(v.type) {
						case etScalar: def = 0;
						case etVector: def = Vec2.get();
						default:
						}
					}else {
						switch(v.def.simple(context)) {
						case eScalar(x): def = x;
						case eVector(x,y): def = Vec2.get(x,y);
						default:
						}
					}
					variables.set(v.name, {type:v.type, value:def});
				}
			case aConstraint(expr):
				posC = expr.simple(context);
			case aLimit(expr,lower,upper):
				if(expr!=null) limits.push({
					limit:expr.simple(context),
					lower:lower.simple(context),
					upper:upper.simple(context)
				}) else {
					this.lower = lower.simple(context);
					this.upper = upper.simple(context);
				}
			default:
		}}

		posC = posC.simple(context);

		//get dimensino of constraint from type
		var type = posC.etype(context);
		dim = switch(type) {
			case etScalar: 1;
			case etVector: 2;
			case etRowVector: throw "Error: Constraint should not be a row-vector"; 0;
			case etMatrix: throw "Error: Constraint should not be a matrix"; 0;
			case etBlock(xs):
				var dim = 0;
				for(x in xs) {
					dim += switch(x) {
					case etScalar: 1;
					case etVector: 2;
					default: throw "Error: If constraint is a block, it should be exactly a block vector containing nothing but scalars and column vectors"; 0;
					}
				}
				dim;
		}

		scale = []; equal = [];
		for(i in 0...dim) { scale.push(0.0); equal.push(true); }

		super(dim);	

		//velocity constraint
		velC = posC.diff(context);

		//jacobian
		J = [];
		for(b in bindices) {
			J.push(velC.diff(context,b+".velocity",0));
			J.push(velC.diff(context,b+".velocity",1));
			J.push(velC.diff(context,b+".angularVel"));
		}

		//effective mass
		effK = null;
		for(i in 0...J.length) {
			var b = bindices[Std.int(i/3)];
			var m = eVariable(b + (if((i%3)==2) "#iinertia" else "#imass"));
			var e = eLet("#J",J[i],eMul(m,eOuter(eVariable("#J"),eVariable("#J")))).simple(context);

			if(effK==null) effK = e;
			else effK = eAdd(effK,e);
		}
		effK = effK.simple(context);
	}

	//-----------------------------------------------------------------------------

	public function getBody(name:String) return bodies.get(name)
	public function setBody(name:String,body:Body) {
		bodies.set(name,registerBody(getBody(name),body));
		return body;
	}

	//-----------------------------------------------------------------------------

	public function getScalar(name:String):Float return variables.get(name).value
	public function getVector(name:String):Vec2  return variables.get(name).value

	public function setScalar(name:String,value:Float) {
		variables.get(name).value = value;
		invalidate();
	}
	public function setVector(name:String,value:Vec2):Vec2 {
		var v = getVector(name);
		if(v==null) v = variables.get(name).value = bindVec2();
		return v.set(value);
	}

	//-----------------------------------------------------------------------------

	private function less(a:Expr,b:Expr) {
		return switch(a) {
			case eScalar(x): switch(b) { case eScalar(y): x < y; default: false; }
			case eVector(x1,y1): switch(b) { case eVector(x2,y2): x1 < x2 || y1 < y2; default: false; }
			default: false;
		}
	}

	//-----------------------------------------------------------------------------

	public override function __validate() {
		//should check for null bodies here.

		//set variables in context
		for(n in variables.keys()) {
			var v = variables.get(n);
			var expr = switch(v.type) {
				case etScalar: eScalar(v.value);
				case etVector: var xy:Vec2 = v.value; eVector(xy.x,xy.y);
				default: null;
			}
			context.replaceContext(n,expr);
		}

		//set body parameters in context that remain fixed
		for(n in bodies.keys()) {
			var b = bodies.get(n);
			context.replaceContext(n+"#imass",   eScalar(b.constraintMass));
			context.replaceContext(n+"#iinertia",eScalar(b.constraintInertia));
		}

		//check limits
		//TODO: Ensure any body-variables in limits used are set in context
		for(l in limits) {
			var limit = l.limit.eval(context);
			var lower = l.lower.eval(context);
			var upper = l.upper.eval(context);
			if(less(limit,lower) || less(upper,limit)) throw "Error: Limit not satisfied on "+l.limit.print()+"="+limit.print()+" and lower="+lower.print()+" and upper="+upper.print();	
		}
	}

	public override function __prepare() {
		//set body parameters remaining fixed in velocity iterations
		for(n in bodies.keys()) {
			var b = bodies.get(n);
			context.replaceContext(n+".position", eVector(b.position.x,b.position.y));
			context.replaceContext(n+".rotation", eScalar(b.rotation));
		}
	}

	/*#if flash @:protected #end */private function setvec(e:Expr,vec:ARRAY<Float>,?off:Int=0) {
		switch(e) {
			case eScalar(x): vec[off++] = x;
			case eVector(x,y): vec[off++] = x; vec[off++] = y;
			case eBlock(xs): 
				for(x in xs) off = setvec(x,vec,off);
			default: throw "wtf";
		}
		return off;
	}

	public override function __position(err:ARRAY<Float>) {
		setvec(posC.eval(context), err);

		//inequality bounding.
		var bounds = [];
		var lowerv = if(lower==null) null else flatten(lower.eval(context));
		var upperv = if(upper==null) null else flatten(upper.eval(context));
		for(i in 0...err.length) {
			var low  = if(lowerv ==null) 0.0 else lowerv[i][0];
			var high = if(upperv==null) 0.0 else upperv[i][0];
			if(equal[i] = (low==high)) {
				err[i] -= low;
				scale[i] = 1.0;
			}else if(err[i]<low) {
				err[i] = low - err[i];
				scale[i] = -1.0;
			}else if(err[i]>high) {
				err[i] -= high;
				scale[i] = 1.0;
			}else
				err[i] = scale[i] = 0.0;
		}
	}
	
	public override function __velocity(err:ARRAY<Float>) {
		//set body parameters changing in velocity iterations
		for(n in bodies.keys()) {
			var b = bodies.get(n);
			context.replaceContext(n+".velocity", eVector(b.constraintVelocity.x,b.constraintVelocity.y));
			context.replaceContext(n+".angularVel", eScalar(b.constraintVelocity.z));
		}
		setvec(velC.eval(context), err);
		for(i in 0...err.length) err[i] *= scale[i];
	}

	//takes literal expression and flattens into 2D array of floats.
	/*#if flash @:protected #end */private function flatten(e:Expr,vert=true):Array<Array<Float>> {
		return switch(e) {
			case eScalar(x): [[x]];
			case eVector(x,y): [[x],[y]];
			case eRowVector(x,y): [[x,y]];
			case eMatrix(a,b,c,d): [[a,b],[c,d]];
			case eBlock(xs):
				var ys = ExprUtils.map(xs, function(x) return flatten(x,!vert));
				//stack vertically/horizontally
				var out:Array<Array<Float>> = [];
				if(!vert) {
					for(y in 0...ys[0].length) {
						var row = [];
						for(e in ys) row = row.concat(e[y]);
						out.push(row);
					}
				}else {
					for(e in ys) out = out.concat(e);
				}
				out;
			default: null;
		}
	}

	public override function __eff_mass(out:ARRAY<Float>) {
		var eff = effK.eval(context);

		//take eff; and produce a full matrix
		var K = flatten(eff);

		//populate out array based on full eff-mass
		var i = 0;
		for(y in 0...K.length) {
			for(x in y...K.length)
				out[i++] = (scale[x]*scale[y])*K[y][x];
		}
	}

	private function dot(a:Array<Array<Float>>,b:ARRAY<Float>) {
		var ret = 0.0;
		for(i in 0...a.length) ret += a[i][0]*b[i]*scale[i];
		return ret;
	}

	public override function __clamp(imp:ARRAY<Float>) {
		for(i in 0...imp.length) if(!equal[i] && imp[i]>0 || scale[i]==0) imp[i] = 0;
	}
	
	public override function __impulse(imp:ARRAY<Float>,body:Body,out:Vec3) {
		var bname = "";
		for(n in bodies.keys()) { if(bodies.get(n)==body) { bname = n; break; } }
		var bind = -1;
		for(i in 0...bindices.length) { if(bindices[i]==bname) { bind = i; break; } }

		//these should all be column vectors like [[j0],[j1]...[j(dim-1)]]
		var Jx = flatten(J[bind*3+0].eval(context));
		var Jy = flatten(J[bind*3+1].eval(context));
		var Jz = flatten(J[bind*3+2].eval(context));
	
		out.x = dot(Jx, imp);
		out.y = dot(Jy, imp);
		out.z = dot(Jz, imp);
	}
}
