package symbolic;

import nape.constraint.UserConstraint;
import nape.geom.Vec2;
import nape.phys.Body;

import symbolic.Expr;
import symbolic.Parser;

using symbolic.Expr.ExprUtils;

class SymbolicConstraint extends UserConstraint {

	#if flash @:protected #end private var context:Context;
	#if flash @:protected #end private var bodies:Hash<Body>;

	#if flash @:protected #end private var posC:Expr;
	#if flash @:protected #end private var velC:Expr;
	#if flash @:protected #end private var J:Array<Expr>;
	#if flash @:protected #end private var effK:Expr;

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

	public function new(constraint:String) {
		var res = ConstraintParser.parse(constraint);

		context = res.context;
		bodies = new Hash<Body>();

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
		var dim = switch(type) {
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

	public function getBody(name:String) return bodies.get(name)
	public function setBody(name:String,body:Body) {
		bodies.set(name,registerBody(getBody(name),body));
		return body;
	}
}
