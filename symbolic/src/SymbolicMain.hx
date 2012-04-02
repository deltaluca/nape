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
		body b1
		body b2

		vector anchor1
		vector anchor2

		let r1 = relative b1.rot anchor1 in
		let r2 = relative b2.rot anchor2 in
	
		(r2 + b2.pos) - (r1 + b1.pos)
		";
		/*var con = new symbolic.SymbolicConstraint(pivot);
		con.setVector("anchor1", new nape.geom.Vec2(50,0));
		con.setVector("anchor2", new nape.geom.Vec2(-50,0));
		b2.angularVel = 5;*/

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

		del cross dir
		";
		var con = new symbolic.SymbolicConstraint(line);
		con.setVector("direction", new nape.geom.Vec2(1,0));
		con.setVector("anchor1", new nape.geom.Vec2(30,0));
		con.setVector("anchor2", new nape.geom.Vec2(-30,0));
		b2.angularVel = 5;

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
/*		var con = new symbolic.SymbolicConstraint(dist);
		con.setScalar("dist",50);
		con.setVector("anchor1", new nape.geom.Vec2(30,0));
		con.setVector("anchor2", new nape.geom.Vec2(-30,0));
		b2.angularVel = 5;*/


		//---------------------------------------

		var angle = "
		body b1
		body b2

		scalar ratio

		b2.rot*ratio - b1.rot
		";
		/*var con = new symbolic.SymbolicConstraint(angle);
		con.setScalar("ratio", 1);
		b2.angularVel = 5;*/

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
		/*var con = new symbolic.SymbolicConstraint(weld);
		con.setScalar("phase",0);
		con.setVector("anchor1", new nape.geom.Vec2(30,0));
		con.setVector("anchor2", new nape.geom.Vec2(-30,0));
		b2.angularVel = 5;*/

		//------------------------------------------

		trace(con.debug());
		con.space = space;
		con.setBody("b1",b1);
		con.setBody("b2",b2);

		(new haxe.Timer(0)).run = function() {
			space.step(1/60);
			debug.clear();
			debug.draw(space);
		};
	}
}
