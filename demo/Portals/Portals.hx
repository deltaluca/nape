package;

import nape.space.Space;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.shape.Circle;
import nape.shape.Polygon;
import nape.geom.Vec2;
import nape.util.BitmapDebug;
import nape.constraint.PivotJoint;

import FixedStep;
import PortalManager;
import PortalData;
import FPS;

class Portals extends FixedStep {
	static function main() {
		new Portals();
	}
	function new() {
		super(1/60);

		var space = new Space();
		var debug = new BitmapDebug(stage.stageWidth,stage.stageHeight,0x333333);
		debug.drawConstraints = true;
		addChild(debug.display);
		addChild(new FPS(stage.stageWidth,60,0,60,0x40000000,0xffffffff,0xa0ff0000));

		var border = new Body(BodyType.STATIC);
		border.shapes.add(new Polygon(Polygon.rect(0,0,-50,stage.stageHeight)));
		border.shapes.add(new Polygon(Polygon.rect(stage.stageWidth,0,50,stage.stageHeight)));
		border.shapes.add(new Polygon(Polygon.rect(0,0,stage.stageWidth,-50)));
		border.shapes.add(new Polygon(Polygon.rect(0,stage.stageHeight,stage.stageWidth,50)));
		border.space = space;

		//-------------------------------------------------------------------------

		for(p in [
			new Vec2(200,225),new Vec2(400,225),new Vec2(300,125),/*new Vec2(300,325),*/
			new Vec2(50,50),new Vec2(550,50),new Vec2(50,400),new Vec2(550,400)
		]) {
			var b = new Body();
			b.position = p;
			b.shapes.add(new Circle(12,new Vec2(12*0.86,-6)));
			b.shapes.add(new Circle(12,new Vec2(0,12)));
			b.shapes.add(new Circle(12,new Vec2(-12*0.86,-6)));
			b.space = space;
			for(s in b.shapes) s.cbTypes.add(PortalManager.Portable);
		}

		//-------------------------------------------------------------------------

		function genportal(pos:Vec2,dir:Vec2,w:Float) {
			var b = new Body(BodyType.STATIC);
			b.position.set(pos);
			b.rotation = dir.angle;

			var d = 10;
			var port = new Polygon(Polygon.box(d,w));
			port.body = b;

			b.shapes.add(new Polygon(Polygon.rect(-d/2,-w/2,d,-d)));
			b.shapes.add(new Polygon(Polygon.rect(-d/2, w/2,d, d)));
			b.shapes.add(new Polygon(Polygon.rect(-d/2,-w/2-d,-d,w+d*2)));
			b.align();

			b.space = space;

			var p = new PortalData(port,port.localCOM.add(new Vec2(d/2.1,0)),new Vec2(1,0),w);
			return p;
		}

		var p1 = genportal(new Vec2(100,225),new Vec2(1,0),150);
		var p2 = genportal(new Vec2(500,225),new Vec2(-1,0),100);
		var p3 = genportal(new Vec2(300,55),new Vec2(0,1),150);
		var p4 = genportal(new Vec2(300,395),new Vec2(0,-1),100);

		p1.target = p2;
		p2.target = p3;
		p3.target = p4;
		p4.target = p1;

		p1.body.type = BodyType.KINEMATIC;
		p2.body.type = BodyType.KINEMATIC;
		p2.body.angularVel = 1;

		//funky portal body now :)
		for(i in 0...0) {
		var b = new Body(BodyType.DYNAMIC,new Vec2(300,225));
		b.shapes.add(new Polygon(Polygon.box(84,100)));
		b.shapes.add(new Polygon(Polygon.rect(-42,-42,-8,-8)));
		b.shapes.add(new Polygon(Polygon.rect(-42,42,-8,8)));
		b.shapes.add(new Polygon(Polygon.rect(42,-42,8,-8)));
		b.shapes.add(new Polygon(Polygon.rect(42,42,8,8)));

		var port1 = new Polygon(Polygon.rect(-42,-42,-8,84));
		var port2 = new Polygon(Polygon.rect(42,-42,8,84));
		port1.body = b;
		port2.body = b;

		b.space = space;
		b.position.y += i*120;
		b.rotation = Math.PI/4;

		var q1 = new PortalData(port1,port1.localCOM.add(new Vec2(-8/2.1,0)),new Vec2(-1,0),84);
		var q2 = new PortalData(port2,port2.localCOM.add(new Vec2( 8/2.1,0)),new Vec2(1,0),84);
		q1.target = q2;
		q2.target = q1;
		}

		//-------------------------------------------------------------------------

		var hand = new PivotJoint(space.world,null,new Vec2(),new Vec2());
		hand.active = false;
		hand.stiff = false;
		hand.space = space;
		stage.addEventListener(flash.events.MouseEvent.MOUSE_DOWN, function (_) {
			var mp = new Vec2(mouseX,mouseY);
			for(b in space.bodiesUnderPoint(mp)) {
				if(b.isDynamic()) {
					hand.body2 = b;
					hand.anchor2 = b.worldPointToLocal(mp);
					hand.active = true;
				}
			}
		});
		stage.addEventListener(flash.events.MouseEvent.MOUSE_UP, function (_) {
			hand.active = false;
		});

		//-------------------------------------------------------------------------

		var manager = new PortalManager(space);
		space.worldLinearDrag = 0.9;
		space.worldAngularDrag = 0.9;

		run(function (dt) {
			p1.body.velocity.y = Math.cos(space.elapsedTime)*50;

			if(hand.active && hand.body2.space==null) { hand.body2 = null; hand.active = false; }
			hand.anchor1.setxy(mouseX,mouseY);

			debug.clear();
			space.step(dt);

			for(b in space.bodies) {
				for(s in b.shapes) {
					var inout = s.cbTypes.has(PortalManager.InOut);
					var porter = s.cbTypes.has(PortalManager.Portable);
					var portal = s.cbTypes.has(PortalManager.Portal);
					var col = (inout?0xff:0)|(porter?0xff00:0)|(portal?0xff0000:0);
					if(col==0) continue;
					if(s.isCircle()) {
						debug.drawFilledCircle(s.worldCOM,s.castCircle.radius,col);
					}else {
						debug.drawFilledPolygon(s.castPolygon.worldVerts,col);
					}
				}
			}

			debug.draw(space);
			debug.flush();
		});
	}
}
