package;

import nape.space.Space;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.space.Broadphase;
import nape.shape.Polygon;
import nape.util.ShapeDebug;
import nape.geom.Vec2;

class Main {
	public static function main() {
		new Main();
	}
	function new() {
		var cur = flash.Lib.current;
		var stage = cur.stage;

		var debug = new ShapeDebug(800,600,0x333333);
		debug.drawShapeAngleIndicators = false;
		cur.addChild(debug.display);
		var space = new Space(new Vec2(0,400),Broadphase.SWEEP_AND_PRUNE);

		var border = new Body(BodyType.STATIC);
		border.shapes.add(new Polygon(Polygon.rect(0,0,-50,stage.stageHeight)));
		border.shapes.add(new Polygon(Polygon.rect(stage.stageWidth,0,50,stage.stageHeight)));
		border.shapes.add(new Polygon(Polygon.rect(0,0,stage.stageWidth,-50)));
		border.shapes.add(new Polygon(Polygon.rect(0,stage.stageHeight,stage.stageWidth,50)));
		border.space = space;

		var boxw = 6;
		var boxh = 12;
		var height = 40; //820 blocks

		for(y in 1...(height+1)) {
			for(x in 0...y) {
				var block = new Body();
				block.position.x = stage.stageWidth/2 - boxw*(y-1)/2 + x*boxw;
				block.position.y = stage.stageHeight - boxh/2 - boxh*(height-y)*0.98;
				block.shapes.add(new Polygon(Polygon.box(boxw,boxh)));
				block.space = space;
			}
		}	

		var txt = new flash.text.TextField();
		txt.defaultTextFormat = new flash.text.TextFormat(null,14,0xffffff);
		cur.addChild(txt);

		var render = true;
		cur.stage.addEventListener(flash.events.KeyboardEvent.KEY_DOWN, function (ev) {
			if(ev.keyCode == flash.ui.Keyboard.SPACE)
				render = !render;
		});
	
		var fps = -1.0;
		var pt = flash.Lib.getTimer();
		cur.addEventListener(flash.events.Event.ENTER_FRAME, function (_) {
			var ct = flash.Lib.getTimer();
			var nfps = 1000/(ct-pt);
			fps = if(fps==-1.0) nfps else fps*0.95+nfps*0.05;
			pt = ct;
			txt.text = Std.string(fps).substr(0,5)+"fps";
			var dt = Math.min(1/40, 1/200 + space.timeStamp*1e-5*30);

			debug.clear();
			space.step(dt,8,8);
			if(render)
				debug.draw(space);
			debug.flush();
		});

	}
}
