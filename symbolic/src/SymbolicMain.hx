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

		var b1 = new nape.phys.Body(); b1.shapes.add(new nape.shape.Circle(20));
		var b2 = new nape.phys.Body(); b2.shapes.add(new nape.shape.Circle(20));
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
		body body1, body2
		vector anchor1, anchor2, direction
		scalar jointMin, jointMax
		
		limit jointMin (-inf) jointMax
		limit |direction| eps inf

		constraint
			let r1 = relative body1.rotation anchor1 in
			let r2 = relative body2.rotation anchor2 in
			let dir = relative body1.rotation direction in
			let del = (r2 + body2.position) - (r1 + body1.position) in
			{ dir cross del
              dir dot del }

		limit constraint { jointMin jointMin } { jointMax jointMax }
		";
		var con = new symbolic.SymbolicConstraint(line);
		con.setVector("direction", new nape.geom.Vec2(1,0));
		con.setVector("anchor1", new nape.geom.Vec2(0,0));
		con.setVector("anchor2", new nape.geom.Vec2(0,0));
		con.setScalar("jointMin",60);
		con.setScalar("jointMax",120);
//		b2.angularVel = 5;
	//	throw con.debug();

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
		/*var con = new symbolic.SymbolicConstraint(dist);
		con.setVector("anchor1", new nape.geom.Vec2(30,0));
		con.setVector("anchor2", new nape.geom.Vec2(-30,0));
		con.setScalar("jointMin",20);
		con.setScalar("jointMax",60);
		b2.angularVel = 5;*/

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
		body body1, body2
		vector anchor1, anchor2
		scalar phase
		
		constraint
			let r1 = relative body1.rotation anchor1 in
			let r2 = relative body2.rotation anchor2 in
			{ (r2 + body2.position) - (r1 + body1.position)
			  body2.rotation - body1.rotation - phase }
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

		var hand = new nape.constraint.PivotJoint(space.world,null,new nape.geom.Vec2(), new nape.geom.Vec2());
		hand.active = false;
		hand.stiff = false;
		hand.space = space;
		flash.Lib.current.stage.addEventListener(flash.events.MouseEvent.MOUSE_DOWN, function (_) {
			var mp = new nape.geom.Vec2(flash.Lib.current.mouseX,flash.Lib.current.mouseY);
			for(b in space.bodiesUnderPoint(mp)) {
				hand.body2 = b;
				hand.anchor2 = b.worldToLocal(mp);
				hand.active = true;
			}
		});
		flash.Lib.current.stage.addEventListener(flash.events.MouseEvent.MOUSE_UP, function (_) hand.active = false);

		(new haxe.Timer(0)).run = function() {
			hand.anchor1.setxy(flash.Lib.current.mouseX,flash.Lib.current.mouseY);
			space.step(1/60);
			debug.clear();
			debug.draw(space);
			var n = b1.localToRelative(con.getVector("direction"));
			var m = new nape.geom.Vec2(-n.y,n.x);
			var p0 = b1.localToWorld(con.getVector("anchor1"));
			var dmax = con.getScalar("jointMax")-con.getScalar("jointMin");
			p0.addeq(n.mul(con.getScalar("jointMin")));
			p0.addeq(m.mul(con.getScalar("jointMin")));
			debug.drawLine(p0,p0.add(n.mul(dmax)),0xff0000);
			debug.drawLine(p0,p0.add(m.mul(dmax)),0xff0000);
			debug.drawLine(p0.add(n.mul(dmax)),p0.add(n.mul(dmax)).add(m.mul(dmax)),0xff0000);
			debug.drawLine(p0.add(m.mul(dmax)),p0.add(n.mul(dmax)).add(m.mul(dmax)),0xff0000);
		};
	}
}
