package {
	//Terrain class, quickly translated into AS3 (untested)

	import nape.space.Space;
	import flash.display.BitmapData;
	import nape.geom.*;
	import nape.phys.*;
	import nape.shape.Polygon;

	public class Terrain {
		private var space:Space;
		private var bitmap:BitmapData;
		private var offset:Vec2;
		private var cellsize:Number;
		private var subsize:Number;

		private var width:int;
		private var height:int;
		private var cells:Array;

		public function Terrain(space:Space, bitmap:BitmapData, offset:Vec2, cellsize:Number, subsize:Number):void {
			this.space = space;
			this.bitmap = bitmap;
			this.offset = offset;
			this.cellsize = cellsize;
			this.subsize = subsize;

			width  = int(Math.ceil(bitmap.width/cellsize));
			height = int(Math.ceil(bitmap.height/cellsize));
			cells = [];
			for(var i:int = 0; i<width*height; i++) cells.push(null);

			invalidate(new AABB(0,0,bitmap.width,bitmap.height));
		}

		private var bounds:AABB;
		//invalidate a region of the terrain to be regenerated.
		public function invalidate(region:AABB):void {
			//compute effected cells
			var x0:int = int(region.min.x/cellsize); if(x0<0) x0 = 0;
			var y0:int = int(region.min.y/cellsize); if(y0<0) y0 = 0;
			var x1:int = int(region.max.x/cellsize); if(x1>= width) x1 = width-1;
			var y1:int = int(region.max.y/cellsize); if(y1>=height) y1 = height-1;

			if(bounds==null) bounds = new AABB(0,0,cellsize,cellsize);
			for(var y:int = y0; y<=y1; y++) {
				for(var x:int = x0; x<=x1; x++) {
					var b:Body = cells[y*width+x];
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
					var polys:GeomPolyList = MarchingSquares.run(iso,bounds,Vec2.weak(subsize,subsize),8);
					if(polys.length==0) continue;

					if(b==null) {
						cells[y*width+x] = b = new Body(BodyType.STATIC);
						b.position = offset;
						b.userData = this;
					}

					//decompose polygons and generate the cell body.
					polys.foreach(function (p:GeomPoly):void {
						var qs:GeomPolyList = p.convex_decomposition();
						qs.foreach(function (q:GeomPoly):void {
							b.shapes.add(new Polygon(q));
						});
					});

					b.space = space;
				}
			}	
		}

		//iso-function for terrain, computed as a linearly-interpolated
		//alpha threshold from bitmap.
		function iso(x:Number,y:Number):Number {
			var ix:int = int(x); if(ix<0) ix = 0; else if(ix>=bitmap.width)  ix = bitmap.width -1;
			var iy:int = int(y); if(iy<0) iy = 0; else if(iy>=bitmap.height) iy = bitmap.height-1;
			var fx:Number = x - ix; if(fx<0) fx = 0; else if(fx>1) fx = 1;
			var fy:Number = y - iy; if(fy<0) fy = 0; else if(fy>1) fy = 1;
			var gx:Number = 1-fx;
			var gy:Number = 1-fy;

			var a00:int = bitmap.getPixel32(ix,iy)>>>24;
			var a01:int = bitmap.getPixel32(ix,iy+1)>>>24;
			var a10:int = bitmap.getPixel32(ix+1,iy)>>>24;
			var a11:int = bitmap.getPixel32(ix+1,iy+1)>>>24;

			var ret:Number = gx*gy*a00 + fx*gy*a10 + gx*fy*a01 + fx*fy*a11;
			return 0x80-ret;
		}
	}
}
