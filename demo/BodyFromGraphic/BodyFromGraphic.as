package {

//translation of the bitmapToBody and graphicToBody methods only.

import nape.geom.MarchingSquares;
import nape.geom.GeomPoly;
import nape.geom.GeomPolyList;
import nape.phys.Body;
import nape.shape.Polygon;
import nape.geom.AABB;
import nape.geom.Vec2;

import flash.display.Bitmap;
import flash.display.PixelSnapping;
import flash.display.Sprite;
import flash.display.DisplayObject;
import flash.display.BitmapData;

public class BodyFromGraphic {
	//take a BitmapData object with alpha channel
	//and produce a nape body from the alpha threshold
	//with input bitmap used to create an assigned graphic displayed
	//appropriately
	public static function bitmapToBody(bitmap:BitmapData,threshold:int=0x80,granularity:Vec2=null):Body {
		var body:Body = new Body();
		
		var bounds:AABB = new AABB(0,0,bitmap.width,bitmap.height);
		var iso:Function = function(x:Number,y:Number):Number {
			//take 4 nearest pixels to interpolate linearlly
			var ix:int = int(x); var iy:int = int(y);
			//clamp in-case of numerical inaccuracies
			if(ix<0) ix = 0; if(iy<0) iy = 0;
			if(ix>=bitmap.width)  ix = bitmap.width-1;
			if(iy>=bitmap.height) iy = bitmap.height-1;
			//
			var fx:Number = x - ix; var fy:Number = y - iy;

			var a11:int = threshold - (bitmap.getPixel32(ix,iy)>>>24);
			var a12:int = threshold - (bitmap.getPixel32(ix+1,iy)>>>24);
			var a21:int = threshold - (bitmap.getPixel32(ix,iy+1)>>>24);
			var a22:int = threshold - (bitmap.getPixel32(ix+1,iy+1)>>>24);

			return a11*(1-fx)*(1-fy) + a12*fx*(1-fy) + a21*(1-fx)*fy + a22*fx*fy;
		}

		//iso surface is smooth from alpha channel + interpolation
		//so less iterations are needed in extraction
		var grain:Vec2 = (granularity==null) ? new Vec2(8,8) : granularity;
		var polys:GeomPolyList = MarchingSquares.run(iso, bounds, grain, 1);
		polys.foreach(function (p:GeomPoly):void {
			var qolys:GeomPolyList = p.simplify(1).convex_decomposition();
			qolys.foreach(function (q:GeomPoly):void {
				body.shapes.add(new Polygon(q));
			});
		});

		//want to align body to it's centre of mass
		//and also have graphic offset correctly
		var anchor:Vec2 = body.localCOM.mul(-1);
		body.translateShapes(anchor);

		body.graphic = new Bitmap(bitmap, PixelSnapping.AUTO, true);
		body.graphicOffset = anchor;
		return body;
	}
	
	//take a graphical object on which hitTestPoint will work
	//and produce a nape body with the exact same positions and shapes
	//with input graphic assigned to the body and display appropriately
	public static function graphicToBody(graphic:DisplayObject,granularity:Vec2=null):Body {
		var body:Body = new Body();
		body.position.setxy(graphic.x,graphic.y);
		body.rotation = graphic.rotation*Math.PI/180;

		//ensure graphic is at (0,0,0)
		graphic.x = graphic.y = graphic.rotation = 0;
		//need to ensure graphic exists on display list for hitTestPoint to work. stupid flash.
		stage.addChild(graphic);

		var bounds:AABB = AABB.fromRect(graphic.getBounds(graphic));
		var iso:Function = function(x:Number,y:Number):Number {
			//canot really do a more complex iso-function
			//with hitTestPoint. return inside iso-surface
			//if we hit at the point, otherwise outside
			return (graphic.hitTestPoint(x,y,true)) ? -1.0 : 1.0;
		}

		//because the iso is not smooth, need to use more iterations for quality extraction
		var grain:Vec2 = (granularity==null) ? new Vec2(8,8) : granularity;
		var polys:GeomPolyList = MarchingSquares.run(iso, bounds, granularity, 6);
		polys.foreach(function (p:GeomPoly):void {
			var qolys:GeomPolyList = p.simplify(1).convex_decomposition();
			qolys.foreach(function (q:GeomPoly):void {
				body.shapes.add(new Polygon(q));
			});
		});

		stage.removeChild(graphic);

		//want to align body to it's centre of mass
		//but also have the graphic offset correctly
		var anchor:Vec2 = body.localCOM.mul(-1);
		body.align();
		
		body.graphic = graphic;
		body.graphicOffset = anchor;
		return body;
	}
}
