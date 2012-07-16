package;

import nape.space.Space;
import nape.geom.GeomPoly;
import nape.phys.Body;
import nape.phys.Material;
import nape.phys.BodyType;
import nape.shape.Polygon;
import nape.shape.Circle;
import nape.util.BitmapDebug;
import nape.geom.Vec2;
import nape.geom.MarchingSquares;

import flash.display.Sprite;

import FixedStep;

class DynamicDestruction extends FixedStep {
	static function main() new DynamicDestruction()
	public function new() {
		super(1/60);

		var space = new Space();
		space.worldLinearDrag = 0;
		space.worldAngularDrag = 0;
		var debug = new BitmapDebug(600,450,0x333333);
		addChild(debug.display);

		var mat = new Material(1,0,0,1,0);

		var borders = new Body(BodyType.STATIC);
		borders.shapes.add(new Polygon(Polygon.rect(0,0,-50,450)));
		borders.shapes.add(new Polygon(Polygon.rect(600,0,50,450)));
		borders.shapes.add(new Polygon(Polygon.rect(0,0,600,-50)));
		borders.shapes.add(new Polygon(Polygon.rect(0,450,600,50)));
		borders.setShapeMaterials(mat);
		borders.space = space;

		for(i in 0...10) {
			var b = new Body();
			b.position.setxy(50+Math.random()*500, 50+Math.random()*350);
			b.shapes.add(new Circle(50,null,mat));

			b.velocity.setxy(Math.random()*200-100,Math.random()*200-100);
			b.angularVel = Math.random()*6-3;

			b.space = space;
		}

		//-----------------------------

		function area(b:Body) {
			var ret = 0.0;
			for(s in b.shapes) ret += s.area;
			return ret;
		}

		var radius = 20;
		function explosion(b:Body, pos:Vec2) {
			var minarea = 400;

			//function determines what is counted as area to be cut away
			//here defined as all points within radius pixels of position
			function inside(x:Float,y:Float) {
				return (pos.sub(new Vec2(x,y)).length < radius);
			}

			//produce possibly new set of Destructables resulting from the cut.
			var dests = Destructable.cut(b,inside);
			if(dests==null) {
				//if new set is null, it means the original one could simply be modified

				//discard if too small
				if(area(b) < minarea)
					b.space = null;
				return;
			}

			//otherwise we have either 0, or more than 1 resulting set of bodies

			//remove old body
			b.space = null;

			//add new bodies, ignoring ones that are too small
			for(d in dests) {
				if(area(d)>=minarea) {
					d.space = space;
				}
			}
		}

		stage.addEventListener(flash.events.MouseEvent.CLICK, function (_) {
			var mp = new Vec2(mouseX,mouseY);
			for(b in space.bodiesInCircle(mp,radius)) {
				if(b.isDynamic())
					explosion(b, mp);
			}
		});

		//-----------------------------

		run(function (dt) {
			debug.clear();

			space.step(dt);

			debug.draw(space);
			debug.flush();
		});
	}
}

class Destructable {
	static var granularity = new Vec2(5,5);

	//cut away from a body based on the function
	//to return true if inside the 'thing' to be cut out of the body
	//if return value is null, the body was re-used.
	//otherwise the body should be destroyed and the new 'set'
	//of bodies used instead.
	static public function cut(body:Body, inside:Float->Float->Bool):Array<Body> {
		//boolean subtraction for iso-function.
		//have no 'distance' so simply return -1 and 1.
		function iso(x:Float,y:Float):Float {
			var p = new Vec2(x,y);
			return if(body.contains(p) && !inside(x,y)) -1 else 1;
		}

		//because we have no distance metric, need to use more iterations
		var npolys = MarchingSquares.run(iso, body.bounds, granularity, 8);
		if(npolys.length==0) return []; //object entirely destroyed!

		//don't call body.clear() since we want to keep things like velocities
		body.shapes.clear();
		body.position.setxy(0,0);
		body.rotation = 0;

		if(npolys.length==1) {
			//destructable and body can be re-used. yay

			var qolys = npolys.at(0).convexDecomposition();
			for(q in qolys)
				body.shapes.add(new Polygon(q));

			body.align();

			return null;
		}else {
			//need to create new destructables and bodies for each connected component
			var ret = [];

			for(p in npolys) {
				var nbody = body.copy();
				var qolys = p.convexDecomposition();
				for(q in qolys)
					nbody.shapes.add(new Polygon(q));
				nbody.align();
				ret.push(nbody);
			}

			return ret;
		}
	}
}
