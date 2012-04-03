package;

import symbolic.Expr;
import symbolic.Parser;
using symbolic.Expr.ExprUtils;

class SymbolicMain {
	static function main() {
		mainparser();
	}

	static function mainparser() {
		var space = new nape.space.Space();
		var debug = new nape.util.ShapeDebug(1,1);
		flash.Lib.current.addChild(debug.display);

		var b1 = new nape.phys.Body(); b1.shapes.add(new nape.shape.Circle(30));
		var b2 = new nape.phys.Body(); b2.shapes.add(new nape.shape.Circle(30));
		b1.space = space; b2.space = space;
		b1.position.setxy(150,150);
		b2.position.setxy(250,150);

		var pivot = " 
		body body1, body2
		vector anchor1, anchor2

		constraint
			let r1 = relative body1.rotation anchor1 in
			let r2 = relative body2.rotation anchor2 in
			(r2 + body2.position) - (r1 + body1.position)
		";
		/*var con = new symbolic.SymbolicConstraint(pivot);
		con.setVector("anchor1", new nape.geom.Vec2(50,0));
		con.setVector("anchor2", new nape.geom.Vec2(-50,0));
		b2.angularVel = 5;*/

		//---------------------------------------

		var line = "
		body b1, b2
		vector anchor1, anchor2, direction

		let r1 = relative b1.rot anchor1 in
		let r2 = relative b2.rot anchor2 in
		let dir = relative b1.rot direction in

		let del = (r2 + b2.pos) - (r1 + b1.pos) in

		del cross dir
		";
		/*var con = new symbolic.SymbolicConstraint(line);
		con.setVector("direction", new nape.geom.Vec2(1,0));
		con.setVector("anchor1", new nape.geom.Vec2(30,0));
		con.setVector("anchor2", new nape.geom.Vec2(-30,0));
		b2.angularVel = 5;*/

		//---------------------------------------

		var dist = "
		body body1, body2
		vector anchor1, anchor2
		scalar jointMin, jointMax

		limit jointMin 0 jointMax
		
		constraint
			let r1 = relative body1.rotation anchor1 in
			let r2 = relative body2.rotation anchor2 in	
			| (body2.position + r2) - (body1.position + r1) |
	
		limit constraint jointMin jointMax
		";
		var con = new symbolic.SymbolicConstraint(dist);
		con.setVector("anchor1", new nape.geom.Vec2(30,0));
		con.setVector("anchor2", new nape.geom.Vec2(-30,0));
		con.setScalar("jointMin",20);
		con.setScalar("jointMax",60);
		b2.angularVel = 5;


		//---------------------------------------

		var angle = "
		body body1, body2
		scalar ratio
		scalar jointMin, jointMax

		limit jointMin (-inf) jointMax

		constraint body2.rotation*ratio - body1.rotation
		limit constraint jointMin jointMax
		";
/*		var con = new symbolic.SymbolicConstraint(angle);
		con.setScalar("ratio", 1);
		con.setScalar("jointMax",Math.PI*2);
		b2.angularVel = 5;*/

		//---------------------------------------

		var weld = "
		body b1, b2
		vector anchor1, anchor2
		scalar phase
		
		let r1 = relative b1.rot anchor1 in
		let r2 = relative b2.rot anchor2 in

		{ (r2 + b2.pos) - (r1 + b1.pos)
		  b2.rot - b1.rot - phase
		}
		";
		/*var con = new symbolic.SymbolicConstraint(weld);
		con.setScalar("phase",0);
		con.setVector("anchor1", new nape.geom.Vec2(30,0));
		con.setVector("anchor2", new nape.geom.Vec2(-30,0));
		b2.angularVel = 5;*/

		//------------------------------------------

		trace(con.debug());
		con.space = space;
		con.setBody("body1",b1);
		con.setBody("body2",b2);

		(new haxe.Timer(0)).run = function() {
			space.step(1/60);
			debug.clear();
			debug.draw(space);
		};
	}
}
