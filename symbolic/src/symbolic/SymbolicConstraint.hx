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
	#if flash @:protected #end private var bodies:Hash<Body>;

	#if flash @:protected #end private var posC:Expr;
	#if flash @:protected #end private var velC:Expr;
	#if flash @:protected #end private var J:Array<Expr>;
	#if flash @:protected #end private var effK:Expr;
	#if flash @:protected #end private var dim:Int;

	//-----------------------------------------------------------------------------

	public function debug():String {
		var ret = "";
		ret += "# constraint context\n";
		ret += "# ------------------\n";
		ret += context.print_context()+"\n";
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
		ret += "\n";
		ret += "# effective-mass matrix\n";
		ret += "# ---------------------\n";
		ret += effK.print();
		return ret;
	}

	//-----------------------------------------------------------------------------

	public function new(constraint:String) {
		var res = ConstraintParser.parse(constraint);

		context = res.context;
		variables = new Hash<{type:EType,value:Dynamic}>();
		bodies = new Hash<Body>();

		for(v in context.vars.keys()) {
			var type = context.vars.get(v).type;
			var def:Dynamic = null;
			switch(type) {
				case etScalar: def = 0;
				case etVector: def = null;
				default: 
			}
			variables.set(v, {type:type, value:def});
		}

		for(b in res.bodies) {
			context.variableContext(b+".pos",etVector,eVariable(b+".vel"));
			context.variableContext(b+".vel",etVector);
			context.variableContext(b+".rot",etScalar,eVariable(b+".angvel"));
			context.variableContext(b+".angvel",etScalar);
			context.variableContext(b+".imass",etScalar);
			context.variableContext(b+".iinertia",etScalar);

			bodies.set(b,null);
		}

		//simplified positional constraint
		posC = res.posc.simple(context);

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

		super(dim);	

		//velocity constraint
		velC = posC.diff(context);

		//jacobian
		J = [];
		for(b in res.bodies) {
			J.push(velC.diff(context,b+".vel",0));
			J.push(velC.diff(context,b+".vel",1));
			J.push(velC.diff(context,b+".angvel"));
		}

		//effective mass
		effK = null;
		for(i in 0...J.length) {
			var b = res.bodies[Std.int(i/3)];
			var m = eVariable(b + (if((i%3)==2) ".iinertia" else ".imass"));
			var e = eMul(m,eOuter(J[i],J[i])).simple(context);
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
			context.replaceContext(n+".imass",   eScalar(b.constraintMass));
			context.replaceContext(n+".iinertia",eScalar(b.constraintInertia));
		}
	}

	public override function __prepare() {
		//set body parameters remaining fixed in velocity iterations
		for(n in bodies.keys()) {
			var b = bodies.get(n);
			context.replaceContext(n+".pos", eVector(b.position.x,b.position.y));
			context.replaceContext(n+".rot", eScalar(b.rotation));
		}
	}

	#if flash @:protected #end private function setvec(e:Expr,vec:ARRAY<Float>,?off:Int=0) {
		switch(e) {
			case eScalar(x): vec[off++] = x;
			case eVector(x,y): vec[off++] = x; vec[off++] = y;
			case eBlock(xs): 
				for(x in xs) off = setvec(x,vec,off);
			default: throw "wtf";
		}
		return off;
	}

	public override function __position(err:ARRAY<Float>)
		setvec(posC.eval(context), err)
	
	public override function __velocity(err:ARRAY<Float>) {
		//set body parameters changing in velocity iterations
		for(n in bodies.keys()) {
			var b = bodies.get(n);
			context.replaceContext(n+".vel", eVector(b.velocity.x,b.velocity.y));
			context.replaceContext(n+".angvel", eScalar(b.angularVel));
		}
		setvec(velC.eval(context), err);
	}

	public override function __eff_mass(eff:ARRAY<Float>) {
		var eff = effK.eval(context);

		//assuming a normal constraint, we will either have:
		// eScalar  for  1 dim constraint
/*		var x = 0; var y = 0;
		function coord() return ((2*dim*y - y*y + y)>>>1) + (x-y);

		function setmat(e:Expr,col:Bool) {
			switch(e) {
				case eScalar(a): eff[coord()] = a; if(col) y++ else x++;
				case eMatrix(a,b,_,d): eff[0] = a; eff[1] = b; eff[2] = c;
				case eBlock(xs):
			}
		}

		setmat(eff);*/
	}

	public override function __impulse(imp:ARRAY<Float>,body:Body,out:Vec3) {
		out.x = out.y = out.z = 0;
	}
}
