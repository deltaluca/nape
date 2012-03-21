package;

import phx.World;
import phx.col.SortedList;
import phx.col.AABB;
import phx.Body;
import phx.Shape;
import phx.Vector;
//import phx.FlashDraw;

class Main {
	public static function main() new Main()
	function new() {
		var cur = flash.Lib.current;
		var stage = cur.stage;

	//	var debug = new FlashDraw(cur.graphics);
		var world = new World(
			new AABB(-50,-50,stage.stageWidth+50,stage.stageHeight+50),
			new SortedList()
		);
		world.gravity.y = 400;

		world.addStaticShape(Shape.makeBox(50,stage.stageHeight,-50,0));
		world.addStaticShape(Shape.makeBox(50,stage.stageHeight,stage.stageWidth,0));
		world.addStaticShape(Shape.makeBox(stage.stageWidth,50,0,-50));
		world.addStaticShape(Shape.makeBox(stage.stageWidth,50,0,stage.stageHeight));

		var boxw = 6;
		var boxh = 12;
		var height = 40;
		
		for(y in 1...(height+1)) {
			for(x in 0...y) {
				var block = new Body(
					stage.stageWidth/2 - boxw*(y-1)/2 + x*boxw,
					stage.stageHeight - boxh/2 - boxh*(height-y)*0.98
				);
				block.addShape(Shape.makeBox(boxw,boxh));
				world.addBody(block);
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
		var timeStamp = 0;
		cur.addEventListener(flash.events.Event.ENTER_FRAME, function (_) {
			var ct = flash.Lib.getTimer();
			var nfps = 1000/(ct-pt);
			fps = if(fps==-1.0) nfps else fps*0.95+nfps*0.05;
			pt = ct;
			txt.text = Std.string(fps).substr(0,5)+"fps";
			var dt = Math.min(1/40, 1/200 + timeStamp*1e-5*30);
			timeStamp++;

			cur.graphics.clear();
			world.step(dt*0+1/60,16);
/*			if(render)
				debug.drawWorld(world);*/
		});

	}
}
