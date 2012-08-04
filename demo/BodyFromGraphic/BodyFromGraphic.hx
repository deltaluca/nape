package;

import nape.space.Space;
import nape.geom.MarchingSquares;
import nape.geom.GeomPoly;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.shape.Polygon;
import nape.util.BitmapDebug;
import nape.geom.AABB;
import nape.geom.Vec2;

import flash.display.Bitmap;
import flash.display.PixelSnapping;
import flash.display.Sprite;
import flash.display.DisplayObject;
import flash.display.BitmapData;

import FixedStep;

@:bitmap("sherlock.png") class Sherlock extends BitmapData {}
class BodyFromGraphic extends FixedStep {
	static function main() { new BodyFromGraphic(); }
	function new() {
		super(1/60);
		var space = new Space(new Vec2(0,600));

		//borders
		var border = new Body(BodyType.STATIC);
		border.shapes.add(new Polygon(Polygon.rect(0,0,-50,450)));
		border.shapes.add(new Polygon(Polygon.rect(0,0,600,-50)));
		border.shapes.add(new Polygon(Polygon.rect(600,0,50,450)));
		border.shapes.add(new Polygon(Polygon.rect(0,450,600,50)));
		border.space = space;

		//create some nape bodies generated from display object graphics.
		for(i in 0...5) {
			var graphic = new Sprite();
			var g = graphic.graphics;
			g.beginFill(0,1);
			g.drawCircle(0,30,15);
			g.drawCircle(-10,-30,10+Math.random()*20);
			g.drawCircle(0,0,10+Math.random()*20);
			g.endFill();

			graphic.x = 100+i*100;
			graphic.y = 100;
			graphic.rotation = Math.random()*360;

			var body = graphicToBody(graphic, new Vec2(5,5));
			body.space = space;
			addChild(body.userData.graphic);
		}

		//create a nape body generated from a bitmap
		for(i in 0...3) {
			var body = bitmapToBody(new Sherlock(0,0), 0x80, new Vec2(6,6));
			body.position.setxy(150+150*i,350);
			body.space = space;
			addChild(body.userData.graphic);
		}

		//overlap debug ontop of everything
		var debug = new BitmapDebug(600,450,0x333333,true);
		debug.display.alpha = 0.25;
		debug.drawConstraints = true;
		addChild(debug.display);

		//mouse dragging
		var hand = new nape.constraint.PivotJoint(space.world,null,new Vec2(), new Vec2());
		hand.space = space;
		hand.stiff = false;
		hand.active = false;

		stage.addEventListener(flash.events.MouseEvent.MOUSE_DOWN, function (_) {
			var mp = new Vec2(mouseX,mouseY);
			for(b in space.bodiesUnderPoint(mp)) {
				if(!b.isDynamic()) continue;
				hand.body2 = b;
				hand.anchor2 = b.worldToLocal(mp);
				hand.active = true;
				break;
			}
		});
		stage.addEventListener(flash.events.MouseEvent.MOUSE_UP, function (_) {
			hand.active = false;
		});

		run(function (dt) {
			debug.clear();

			hand.anchor1.setxy(mouseX,mouseY);
			space.step(dt);

			debug.draw(space);
			debug.flush();

            space.visitBodies(function (b) {
                var g = b.userData.graphic;
                if (g == null) return;

                var p = b.localToWorld(b.userData.graphicOffset);
                g.x = p.x;
                g.y = p.y;
                p.dispose();

                g.rotation = b.rotation*180/Math.PI;
            });
		});
	}

	//take a BitmapData object with alpha channel
	//and produce a nape body from the alpha threshold
	//with input bitmap used to create an assigned graphic displayed
	//appropriately
	function bitmapToBody(bitmap:BitmapData,?threshold=0x80,?granularity:Vec2=null):Body {
		var body = new Body();

		var bounds = new AABB(0,0,bitmap.width,bitmap.height);
		function iso(x:Float,y:Float):Float {
			//take 4 nearest pixels to interpolate linearlly
			var ix = Std.int(x); var iy = Std.int(y);
			//clamp in-case of numerical inaccuracies
			if(ix<0) ix = 0; if(iy<0) iy = 0;
			if(ix>=bitmap.width)  ix = bitmap.width-1;
			if(iy>=bitmap.height) iy = bitmap.height-1;
			//
			var fx = x - ix; var fy = y - iy;

			var a11 = threshold - (bitmap.getPixel32(ix,iy)>>>24);
			var a12 = threshold - (bitmap.getPixel32(ix+1,iy)>>>24);
			var a21 = threshold - (bitmap.getPixel32(ix,iy+1)>>>24);
			var a22 = threshold - (bitmap.getPixel32(ix+1,iy+1)>>>24);

			return a11*(1-fx)*(1-fy) + a12*fx*(1-fy) + a21*(1-fx)*fy + a22*fx*fy;
		}

		//iso surface is smooth from alpha channel + interpolation
		//so less iterations are needed in extraction
		var grain = if(granularity==null) new Vec2(8,8) else granularity;
		var polys = MarchingSquares.run(iso, bounds, grain, 1);
		for(p in polys) {
			var qolys = p.simplify(1).convexDecomposition();
			for(q in qolys)
				body.shapes.add(new Polygon(q));
		}

		//want to align body to it's centre of mass
		//and also have graphic offset correctly
		var anchor = body.localCOM.mul(-1);
		body.translateShapes(anchor);

		body.userData.graphic = new Bitmap(bitmap, PixelSnapping.AUTO, true);
		body.userData.graphicOffset = anchor;
		return body;
	}

	//take a graphical object on which hitTestPoint will work
	//and produce a nape body with the exact same positions and shapes
	//with input graphic assigned to the body and display appropriately
	function graphicToBody(graphic:DisplayObject,?granularity:Vec2=null):Body {
		var body = new Body();
		body.position.setxy(graphic.x,graphic.y);
		body.rotation = graphic.rotation*Math.PI/180;

		//ensure graphic is at (0,0,0)
		graphic.x = graphic.y = graphic.rotation = 0;
		//need to ensure graphic exists on display list for hitTestPoint to work. stupid flash.
		stage.addChild(graphic);

		var bounds = AABB.fromRect(graphic.getBounds(graphic));
		function iso(x:Float,y:Float):Float {
			//canot really do a more complex iso-function
			//with hitTestPoint. return inside iso-surface
			//if we hit at the point, otherwise outside
			return if(graphic.hitTestPoint(x,y,true)) -1.0 else 1.0;
		}

		//because the iso is not smooth, need to use more iterations for quality extraction
		var grain = if(granularity==null) new Vec2(8,8) else granularity;
		var polys = MarchingSquares.run(iso, bounds, granularity, 6);
		for(p in polys) {
			var qolys = p.simplify(1).convexDecomposition();
			for(q in qolys)
				body.shapes.add(new Polygon(q));
		}

		stage.removeChild(graphic);

		//want to align body to it's centre of mass
		//but also have the graphic offset correctly
		var anchor = body.localCOM.mul(-1);
		body.align();

		body.userData.graphic = graphic;
		body.userData.graphicOffset = anchor;
		return body;
	}
}
