package;

import nape.space.Space;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.geom.MarchingSquares;
import nape.shape.Polygon;
import nape.shape.Circle;
import nape.geom.Vec2;
import nape.geom.AABB;
import nape.util.BitmapDebug;

import flash.display.BitmapData;
import flash.display.Sprite;

import FixedStep;

class DestructableTerrain extends FixedStep {
	static function main() { new DestructableTerrain(); }
	function new() {
		super(1/60);

		var space = new Space(new Vec2(0,500));
		var debug = new BitmapDebug(stage.stageWidth,stage.stageHeight,0x333333);
		addChild(debug.display);

		//border
		var border = new Body(BodyType.STATIC);
		border.shapes.add(new Polygon(Polygon.rect(0,0,-50,stage.stageHeight)));
		border.shapes.add(new Polygon(Polygon.rect(0,0,stage.stageWidth,-50)));
		border.shapes.add(new Polygon(Polygon.rect(0,stage.stageHeight,stage.stageWidth,50)));
		border.shapes.add(new Polygon(Polygon.rect(stage.stageWidth,0,50,stage.stageHeight)));
		border.space = space;

		//terrain
		var bit = new BitmapData(stage.stageWidth,stage.stageHeight,true,0);
		bit.perlinNoise(200,200,2,0x3ed,false,true,flash.display.BitmapDataChannel.ALPHA,false);
		var terrain = new Terrain(space,bit,new Vec2(),30,5);

		//shape to cut out of terrain
		var bomb = new Sprite();
		bomb.graphics.beginFill(0xffffff,1);
		bomb.graphics.drawCircle(0,0,40);

		function explosion(mp:Vec2) {
			bit.draw(bomb,new flash.geom.Matrix(1,0,0,1,mp.x,mp.y),null,flash.display.BlendMode.ERASE);

			var region = AABB.fromRect(bomb.getBounds(bomb));
			region.x += mp.x;
			region.y += mp.y;
			terrain.invalidate(region);
		}

		//----------------------------------

		stage.addEventListener(flash.events.MouseEvent.CLICK, function (_) {
			var mp = new Vec2(mouseX,mouseY);
			for(b in space.bodiesUnderPoint(mp)) {
				if(b.isStatic() && b.userData==terrain) {
					explosion(mp);
					return;
				}
			}

			//otherwise, generate body at point
			var b = new Body(BodyType.DYNAMIC,mp);
			if(Math.random()<0.333)
				b.shapes.add(new Circle(10+Math.random()*20));
			else {
				var p = new Polygon(Polygon.regular(
						20+Math.random()*40,
						20+Math.random()*40,
						Std.int(Math.random()*3+3)
				));
				p.body = b;
			}
			b.space = space;
		});

		//----------------------------------

		run(function (dt) {
			debug.clear();
			space.step(1/60);
			debug.draw(space);
			debug.flush();
		});
	}
}

class Terrain {
	var space:Space;
	var bitmap:BitmapData;
	var offset:Vec2;
	var cellsize:Float;
	var subsize:Float;

	var width:Int;
	var height:Int;
	var cells:Array<Body>;

	public function new(space:Space, bitmap:BitmapData, offset:Vec2, cellsize:Float, subsize:Float) {
		this.space = space;
		this.bitmap = bitmap;
		this.offset = offset;
		this.cellsize = cellsize;
		this.subsize = subsize;

		width  = Math.ceil(bitmap.width/cellsize);
		height = Math.ceil(bitmap.height/cellsize);
		cells = [];
		for(i in 0...width*height) cells.push(null);

		invalidate(new AABB(0,0,bitmap.width,bitmap.height));
	}

	var bounds:AABB;
	//invalidate a region of the terrain to be regenerated.
	public function invalidate(region:AABB) {
		//compute effected cells
		var x0 = Std.int(region.min.x/cellsize); if(x0<0) x0 = 0;
		var y0 = Std.int(region.min.y/cellsize); if(y0<0) y0 = 0;
		var x1 = Std.int(region.max.x/cellsize); if(x1>= width) x1 = width-1;
		var y1 = Std.int(region.max.y/cellsize); if(y1>=height) y1 = height-1;

		if(bounds==null) bounds = new AABB(0,0,cellsize,cellsize);
		for(y in y0...(y1+1)) {
			for(x in x0...(x1+1)) {
				var b = cells[y*width+x];
				if(b!=null) {
					//if cell body exists, clear it for re-use
					b.space = null;
					b.clear();
					b.position = offset;
					b.userData = this;
				}
				
				//compute polygons in cell
				bounds.x = x*cellsize;
				bounds.y = y*cellsize;
				var polys = MarchingSquares.run(iso,bounds,Vec2.weak(subsize,subsize),8);
				if(polys.length==0) continue;

				if(b==null) {
					cells[y*width+x] = b = new Body(BodyType.STATIC);
					b.position = offset;
					b.userData = this;
				}

				//decompose polygons and generate the cell body.
				for(p in polys) {
					var qs = p.convex_decomposition();
					for(q in qs)
						b.shapes.add(new Polygon(q));
				}

				b.space = space;
			}
		}	
	}

	//iso-function for terrain, computed as a linearly-interpolated
	//alpha threshold from bitmap.
	function iso(x:Float,y:Float):Float {
		var ix = Std.int(x); if(ix<0) ix = 0; else if(ix>=bitmap.width)  ix = bitmap.width -1;
		var iy = Std.int(y); if(iy<0) iy = 0; else if(iy>=bitmap.height) iy = bitmap.height-1;
		var fx = x - ix; if(fx<0) fx = 0; else if(fx>1) fx = 1;
		var fy = y - iy; if(fy<0) fy = 0; else if(fy>1) fy = 1;
		var gx = 1-fx;
		var gy = 1-fy;

		var a00 = bitmap.getPixel32(ix,iy)>>>24;
		var a01 = bitmap.getPixel32(ix,iy+1)>>>24;
		var a10 = bitmap.getPixel32(ix+1,iy)>>>24;
		var a11 = bitmap.getPixel32(ix+1,iy+1)>>>24;

		var ret = gx*gy*a00 + fx*gy*a10 + gx*fy*a01 + fx*fy*a11;
		return 0x80-ret;
	}
}
