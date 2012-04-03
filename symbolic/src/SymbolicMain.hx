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

		var walls = new nape.phys.Body(nape.phys.BodyType.STATIC);
		var w = flash.Lib.current.stage.stageWidth;
		var h = flash.Lib.current.stage.stageHeight;
		walls.shapes.add(new nape.shape.Polygon(nape.shape.Polygon.rect(0,0,-50,h)));
		walls.shapes.add(new nape.shape.Polygon(nape.shape.Polygon.rect(w,0,50,h)));
		walls.shapes.add(new nape.shape.Polygon(nape.shape.Polygon.rect(0,0,w,-50)));
		walls.shapes.add(new nape.shape.Polygon(nape.shape.Polygon.rect(0,h,w,50)));
		walls.space = space;

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

		var box = "
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
/*		var con = new symbolic.SymbolicConstraint(box);
		con.setVector("direction", new nape.geom.Vec2(1,0));
		con.setVector("anchor1", new nape.geom.Vec2(0,0));
		con.setVector("anchor2", new nape.geom.Vec2(10,0));
		con.setScalar("jointMin",30);
		con.setScalar("jointMax",60);*/
//		b2.angularVel = 5;
	//	throw con.debug();

		//---------------------------------------

		var donut = "
		body body1, body2
		vector anchor1a, anchor1b, anchor2
		scalar jointMin, jointMax

		limit jointMin 0 jointMax
		
		constraint
			let r1a = relative body1.rotation anchor1a in
			let r1b = relative body1.rotation anchor1b in
			let r2 = relative body2.rotation anchor2 in 
			let del = (r2 + body2.position) - body1.position in
			  | del - r1a | + | del - r1b |

		limit constraint jointMin jointMax
		";
		var con = new symbolic.SymbolicConstraint(donut);
		con.setVector("anchor1a", new nape.geom.Vec2(40,0));
		con.setVector("anchor1b", new nape.geom.Vec2(-40,0));
		con.setVector("anchor2", new nape.geom.Vec2(20,0));
		con.setScalar("jointMin",100);
		con.setScalar("jointMax",120);
		trace(donut);

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

//		trace(con.debug());
		con.space = space;
		con.setBody("body1",b1);
		con.setBody("body2",b2);

		space.worldLinearDrag = space.worldAngularDrag = 0.8;

		var hand = new nape.constraint.PivotJoint(space.world,null,new nape.geom.Vec2(), new nape.geom.Vec2());
		hand.active = false;
		hand.stiff = false;
		hand.frequency = 10;
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

		var eps = new flash.display.Sprite();
		flash.Lib.current.addChild(eps);

		(new haxe.Timer(0)).run = function() {
			hand.anchor1.setxy(flash.Lib.current.mouseX,flash.Lib.current.mouseY);
			space.step(1/60);
			debug.clear();
			debug.draw(space);
			var p0a = b1.localToWorld(con.getVector("anchor1a"));
			var p0b = b1.localToWorld(con.getVector("anchor1b"));
			debug.drawCircle(p0a,2,0xff00ff);
			debug.drawCircle(p0b,2,0xff00ff);
			debug.drawCircle(b2.localToWorld(con.getVector("anchor2")),2,0xff);

			// f = distance from centre to a focus (half distance anchor1a->anchor1b)
			// limit = width
			// f = sqrt(limit^2 + minor^2) -> minor = sqrt(f^2 - limit^2)

			var centre = p0b.add(p0a).mul(0.5);
			var f = (p0b.sub(p0a)).length/2;
			var min = con.getScalar("jointMin"); var h0 = Math.sqrt(min*min*0.25-f*f)*2;
			var max = con.getScalar("jointMax"); var h1 = Math.sqrt(max*max*0.25-f*f)*2;

			eps.rotation = b1.rotation*180/Math.PI+Math.PI/2;
			eps.x = centre.x;
			eps.y = centre.y;
			var g = eps.graphics;
			g.clear();
			g.lineStyle(1,0xff0000,1);
			g.drawEllipse(-min/2,-h0/2,min,h0);
			g.drawEllipse(-max/2,-h1/2,max,h1);
		};

	}
}
