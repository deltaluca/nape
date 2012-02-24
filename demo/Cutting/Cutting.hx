package;

import nape.util.BitmapDebug;
import nape.geom.GeomPoly;
import nape.geom.Vec2;
import nape.space.Space;

class Cutting extends flash.display.Sprite {
	static function main() {
		flash.Lib.current.addChild(new Cutting());
	}
	function new() {
		super();

		//we don't use space for simulation, purely for it's broadphase.
		var space = new Space();

		var debug = new BitmapDebug(600,450,0x333333);
		addChild(debug.display);

		var circs:Array<Body> = [];
		var poly = new GeomPoly();
		function clear() {
		}

		function render() {
			var handlesize = 3;

			debug.clear();
			debug.drawFilledPolygon(poly,0x555555);
			debug.drawPolygon(poly,0x999999);
			for(p in poly) {
				debug.drawFilledCircle(p,handlesize,0x666666);
				debug.drawCircle(p,handlesize,0xaaaaaa);
			}
			debug.flush();
		}

		render();
	}
}
