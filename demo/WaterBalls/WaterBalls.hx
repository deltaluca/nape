package;

import nape.space.Space;

import nape.phys.Body;
import nape.phys.BodyType;

import nape.shape.Circle;
import nape.shape.Polygon;

import nape.constraint.PivotJoint;

import nape.geom.MarchingSquares;
import nape.geom.Vec2;
import nape.geom.AABB;

import nape.util.BitmapDebug;

class WaterBalls {
	static function main() {
		var root = flash.Lib.current;

		var debug = new BitmapDebug(800,400,0x333333);
		debug.drawShapeAngleIndicators = false;
		root.addChild(debug.display);

		var space = new Space(new Vec2(0,400));

		//border
		var border = new Body(BodyType.STATIC);
		border.shapes.add(new Polygon(Polygon.rect(0,  0,-20,400)));
		border.shapes.add(new Polygon(Polygon.rect(800,0, 20,400)));
		border.shapes.add(new Polygon(Polygon.rect(0,  0,800,-20)));
		border.shapes.add(new Polygon(Polygon.rect(0,400,800, 20)));
		border.space = space;

		//ramps - use marching squares because we cannot be bothered to draw them manually.
		var ramp_iso = function(x:Float, y:Float) {
			var sin = Math.sin(x*Math.PI*1.5/800);
			sin *= sin;
			return (400-y) - sin*100*(1+x/800);
		}
		var ramp_polys = MarchingSquares.run(ramp_iso,new AABB(0,0,800,400),new Vec2(10,10),2,new Vec2(100,100));
		var ramp = new Body(BodyType.STATIC);
		for(poly in ramp_polys) {
			var polys = poly.convex_decomposition();
			for(p in polys) ramp.shapes.add(new Polygon(p));
		}
		ramp.space = space;

		//water balls!
		//well not really water given how 'thick' and viscous they are... but still!
		for(x in 0...3) {
			var ball = new Body();
			ball.position.setxy(800/3*(x+0.5), 100);

			var circle = new Circle(50);
			circle.fluidEnabled = true;
			circle.fluidProperties.density = circle.material.density = 2;
			circle.fluidProperties.viscosity = 10;
			//so they don't flow into eachother
			circle.filter.fluidGroup = 2;
			circle.filter.fluidMask = ~2;	
			
			circle.body = ball;
			ball.space = space;
		}

		///aaaaand lots of circles with some out-of-this-world rolling friction
		for(i in 0...500) {
			var ball = new Body();
			ball.shapes.add(new Circle(4));
			ball.space = space;
			ball.position.setxy(Math.random()*800,Math.random()*200);
			var mat = ball.shapes.at(0).material;
			//this value is absolutely out of this world big!
			mat.rollingFriction = 1000;
		}

		//mouse grabbing
		var hand = new PivotJoint(space.world,space.world,new Vec2(), new Vec2());
		hand.active = false;
		hand.space = space;
		//soften
		hand.stiff = false;
		hand.frequency = 4;
		hand.maxForce = 60000;

		root.stage.addEventListener(flash.events.MouseEvent.MOUSE_DOWN, function(_) {
			var mouse = new Vec2(root.mouseX,root.mouseY);
			var bodies = space.bodiesUnderPoint(mouse);

			var grab = null;
			for(b in bodies) {
				if(!b.isDynamic()) continue;
				//choose fluid objects in prefernce to non-fluid objects.
				var fluid = b.shapes.at(0).fluidEnabled;
				if(grab==null || fluid) grab = b;
			}
			if(grab==null) return;

			hand.body2 = grab;
			hand.anchor2 = grab.worldToLocal(mouse);
			hand.active = true;
		});

		root.stage.addEventListener(flash.events.MouseEvent.MOUSE_UP, function(_) {
			hand.active = false;
		});

		//main loop.
		(new haxe.Timer(Std.int(1/40))).run = function() {
			hand.anchor1.setxy(root.mouseX,root.mouseY);
			space.step(1/40, 6,6);

			debug.clear();
			debug.draw(space);
			debug.flush();
		}
	}
}
