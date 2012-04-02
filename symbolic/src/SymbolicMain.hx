package;

import symbolic.Expr;
import symbolic.Parser;
using symbolic.Expr.ExprUtils;

class SymbolicMain {
	static function main() {
		mainparser();
	}

	static function mainparser() {
		var pivot = " 
		body b1
		body b2

		vector anchor1
		vector anchor2

		let r1 = relative b1.rot anchor1 in
		let r2 = relative b2.rot anchor2 in
	
		(r2 + b2.pos) - (r1 + b1.pos)
		";
		//test(pivot);
		//var con = new symbolic.SymbolicConstraint(pivot);
		//trace(con.debug());

		//---------------------------------------

		var line = "
		body b1
		body b2
	
		vector anchor1
		vector anchor2
		vector direction

		let r1 = relative b1.rot anchor1 in
		let r2 = relative b2.rot anchor2 in
		let dir = relative b1.rot direction in

		let del = (r2 + b2.pos) - (r1 + b1.pos) in

		{ del dot dir
		  del cross dir
		}
		";
		//var con = new symbolic.SymbolicConstraint(line);
		//trace(con.debug());

		//---------------------------------------

		var dist = "
		body b1
		body b2

		vector anchor1
		vector anchor2
		scalar dist
		
		let r1 = relative b1.rot anchor1 in
		let r2 = relative b2.rot anchor2 in
		
		| (b2.pos + r2) - (b1.pos + r1) | - dist
		";
		//var con = new symbolic.SymbolicConstraint(dist);
		//trace(con.debug());

		//---------------------------------------

		var angle = "
		body b1
		body b2

		scalar ratio

		b2.rot*ratio - b1.rot
		";
		//var con = new symbolic.SymbolicConstraint(angle);
		//con.setScalar("ratio", 2);
		//test(con);

		//---------------------------------------

		var weld = "
		body b1
		body b2
		
		vector anchor1
		vector anchor2
		scalar phase
		
		let r1 = relative b1.rot anchor1 in
		let r2 = relative b2.rot anchor2 in

		{ (r2 + b2.pos) - (r1 + b1.pos)
		  b2.rot - b1.rot - phase
		}
		";
		var con = new symbolic.SymbolicConstraint(weld);
		con.setScalar("phase",0);
		con.setVector("anchor1", new nape.geom.Vec2(10,20));
		con.setVector("anchor2", new nape.geom.Vec2(1,2));
		test(con);
	}
}
