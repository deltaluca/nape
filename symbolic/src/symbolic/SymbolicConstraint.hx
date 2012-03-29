package symbolic;

import nape.constraint.UserConstraint;
import nape.geom.Vec2;
import nape.phys.Body;

import symbolic.Expr;
import symbolic.Parser;

using ExprUtils;

class SymbolicConstraint extends UserConstraint {

	#if flash @:protected #end private var context:Context;
	#if flash @:protected #end private var bodies:Array<{body:Body,name:String}>;

	#if flash @:protected #end private var posC:Expr;

	public function new(constraint:String) {
		var res = Parser.parse(constraint);

		context = res.context;
		bodies = new Array<{body:Body,name:String}>();

		for(b in res.bodies) {
			context.variableContext(b+".pos",etVector,eVariable(b+".vel"));
			context.variableContext(b+".vel",etVector);
			context.variableContext(b+".rot",etScalar,eVariable(b+".angvel"));
			context.variableContext(b+".angvel",etScalar);
			context.variableContext(b+".imass",etScalar);
			context.variableContext(b+".iinertia",etScalar);

			bodies.push({body:null,name:b});
		}

		posC = res.posc.simple(context);

		var type = posC.etype();
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
	}
}
