package {

import nape.util.Debug;
import nape.util.BitmapDebug;
import nape.geom.GeomPoly;
import nape.geom.GeomPolyList;
import nape.geom.GeomVertexIterator;
import nape.geom.Vec2;

import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;

public class Cutting extends Sprite {
	public function Cutting():void {
		super();
		if(stage!=null) init();
		else addEventListener(Event.ADDED_TO_STAGE, init);
	}

	private function init(ev:Event=null):void {
		if(ev!=null) removeEventListener(Event.ADDED_TO_STAGE, init);

		var debug:Debug = new BitmapDebug(600,450,0x333333);
		addChild(debug.display);

		var handlesize:Number = 4;
		var segsize:Number = 6;
		var subsize:Number = 2;

		var poly:GeomPoly = new GeomPoly([new Vec2(100,100),new Vec2(200,150),new Vec2(300,100),new Vec2(100,300),new Vec2(200,300),new Vec2(300,300)]);
		var seg0:Vec2 = new Vec2(150,50);
		var seg1:Vec2 = new Vec2(150,225);

		var render:Function = function():void {
			var ite:GeomVertexIterator;
			var p:Vec2;

			debug.clear();

			debug.drawFilledPolygon(poly,0x555555);
			debug.drawPolygon(poly,0x999999);
			ite = poly.iterator();
			while(ite.hasNext()) {
				p = ite.next();
				debug.drawFilledCircle(p,handlesize,0x666666);
				debug.drawCircle(p,handlesize,0xaaaaaa);
			}

			var simples:GeomPolyList = poly.simpleDecomposition();
			simples.foreach(function (poly:GeomPoly):void {
				var polys:GeomPolyList = poly.cut(seg0,seg1,true,true);
				polys.foreach(function (p:GeomPoly):void {
					var ite:GeomVertexIterator;
					var q:Vec2;

					var max:Number = 0.0;
					ite = p.iterator();
					while(ite.hasNext()) {
						q = ite.next();
						var dot:Number = q.sub(seg0).cross(seg1.sub(seg0));
						if(dot*dot>max*max) max = dot;
					}
					debug.drawFilledPolygon(p,(max>0) ? 0x55aa55 : 0xaa55aa);
					debug.drawPolygon(p,(max>0) ? 0x99ff99 : 0xff99ff);
					ite = p.iterator();
					while(ite.hasNext()) {
						q = ite.next();
						debug.drawFilledCircle(q,subsize,max > 0 ? 0x66bb66 : 0xbb66bb);
						debug.drawCircle(q,subsize,max > 0 ? 0xaaffaa : 0xffaaff);
					}
				});
			});

			debug.drawLine(seg0,seg1,0xffffff);
			debug.drawFilledCircle(seg0,segsize,0xcc0000);
			debug.drawCircle(seg0,segsize,0xff0000);
			debug.drawFilledCircle(seg1,segsize,0xcc);
			debug.drawCircle(seg1,segsize,0xff);

			debug.flush();
		}
		render();

		var mdrag:Function = null;
		stage.addEventListener(MouseEvent.MOUSE_DOWN, function (ev:Event):void {
			var mp:Vec2 = new Vec2(mouseX,mouseY);
			var s0:Number = mp.sub(seg0).length;
			var s1:Number = mp.sub(seg1).length;
			if(s0<segsize || s1<segsize) {
				var seg:Vec2 = (s0<segsize) ? seg0 : seg1;
				var delta:Vec2 = mp.sub(seg);
				mdrag = function(mp:Vec2):void {
					seg.set(mp.sub(delta));
					render();
				}
				return;
			}

			var ite:GeomVertexIterator = poly.iterator();
			while(ite.hasNext()) {
				var p:Vec2 = ite.next();
				if(mp.sub(p).length < handlesize) {
					var delta2:Vec2 = mp.sub(p);
					mdrag = function(mp:Vec2):void {
						p.set(mp.sub(delta2));
						render();
					}
					return;
				}
			}
		});

		stage.addEventListener(MouseEvent.MOUSE_UP, function(ev:Event):void { mdrag = null; });
		stage.addEventListener(MouseEvent.MOUSE_MOVE, function(ev:Event):void {
			if(mdrag==null) return;
			var mp:Vec2 = new Vec2(mouseX,mouseY);
			mdrag(mp);
		});
	}
}
}
