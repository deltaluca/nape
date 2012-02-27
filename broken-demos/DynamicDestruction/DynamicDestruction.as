package {
	//Translation of Destructable class only.
	//(untested)

	import nape.geom.Vec2;
	import nape.phys.Body;
	import nape.geom.MarchingSquares;
	import nape.geom.GeomPoly;
	import nape.geom.GeomPolyList;
	import nape.shape.Polygon;

	public class Destructible {
		private static const granularity = new Vec2(5,5);

		static public function cut(body:Body, inside:Function):Vector.<Body> {
			var iso:Function = function(x:Number,y:Number):Number {
				var p:Vec2 = new Vec2(x,y);
				return (body.contains(p) && !inside(x,y)) ? -1.0 : 1.0;
			};

			var npolys:GeomPolyList = MarchingSquares.run(iso, body.bounds, granularity, 8);
			if(npolys.length==0) return new Vector.<Body>();
		
			body.shapes.clear();
			body.position.setxy(0,0);
			body.rotation = 0;

			if(npolys.length==1) {
				var qolys:GeomPolyList = npolys.at(0).convex_decomposition();
				qolys.foreach(function (q:GeomPoly):void {
					body.shapes.add(new Polygon(q));
				});

				body.align();

				return null;
			}else {
				var ret:Vector.<Body> = new Vector.<Body>();

				npolys.foreach(function (p:GeomPoly):void {
					var nbody:Body = body.copy();
					var qolys:GeomPolyList = p.convex_decomposition();
					qolys.foreach(function (q:GeomPoly):void {
						nbody.shapes.add(new Polygon(q));
					});
					nbody.align();
					ret.push(nbody);
				});

				return ret;
			}
		}
	}
}
