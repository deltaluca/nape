package;

import nape.util.BitmapDebug;
import nape.geom.GeomPoly;
import nape.geom.Vec2;

class Cutting extends flash.display.Sprite {
	static function main() {
		flash.Lib.current.addChild(new Cutting());
	}
	function new() {
		super();
		var stage = flash.Lib.current.stage;

		var debug = new BitmapDebug(600,450,0x333333);
		addChild(debug.display);

		var handlesize = 4;
		var segsize = 6;

		var poly = new GeomPoly([new Vec2(100,100),new Vec2(200,100),new Vec2(300,100),new Vec2(300,200),new Vec2(300,300),new Vec2(200,300),new Vec2(100,300),new Vec2(100,200)]);
		var seg0 = new Vec2(50,225);
		var seg1 = new Vec2(550,225);

		function render() {
			debug.clear();

			if(poly.size()>2) {
				debug.drawFilledPolygon(poly,0x555555);
				debug.drawPolygon(poly,0x999999);
				for(p in poly) {
					debug.drawFilledCircle(p,handlesize,0x666666);
					debug.drawCircle(p,handlesize,0xaaaaaa);
				}
			}

			var polys = poly.cut(seg0,seg1,true,true);
			for(p in polys) {
				var above = false;
				for(q in p) {
					if(q.sub(seg0).cross(seg1.sub(seg0))<0) {
						above = true;
						break;
					}
				}
				debug.drawPolygon(p,above ? 0xff00 : 0xff00ff);
			}

			debug.drawLine(seg0,seg1,0xffffff);
			debug.drawFilledCircle(seg0,segsize,0xcc0000);
			debug.drawCircle(seg0,segsize,0xff0000);
			debug.drawFilledCircle(seg1,segsize,0xcc);
			debug.drawCircle(seg1,segsize,0xff);

			debug.flush();
		}
		render();

		var mdrag:Vec2->Void = null;
		stage.addEventListener(flash.events.MouseEvent.MOUSE_DOWN, function (_) {
			var mp = new Vec2(mouseX,mouseY);
			var s0 = mp.sub(seg0).length;
			var s1 = mp.sub(seg1).length;
			if(s0<segsize || s1<segsize) {
				var seg = if(s0<segsize) seg0 else seg1;
				var delta = mp.sub(seg);
				mdrag = function(mp:Vec2) {
					seg.set(mp.sub(delta));
					render();
				};
				return;
			}

			for(p in poly) {
				if(mp.sub(p).length < handlesize) {
					var delta2 = mp.sub(p);
					mdrag = function(mp:Vec2) {
						p.set(mp.sub(delta2));
						render();
					}
					return;
				}
			}
		});

		stage.addEventListener(flash.events.MouseEvent.MOUSE_UP, function(_) mdrag = null);
		stage.addEventListener(flash.events.MouseEvent.MOUSE_MOVE, function(_) {
			if(mdrag==null) return;
			var mp = new Vec2(mouseX,mouseY);
			mdrag(mp);
		});
	}
}
