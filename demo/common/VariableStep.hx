package;

import flash.Lib;

class VariableStep extends flash.display.Sprite {
	var fps:Float;

	var pt:Int;

	var txt:flash.text.TextField;

	public function new(?fps_colour=0xffffff) {
		super();
		Lib.current.addChild(this);

		fps = -1.0;

		txt = new flash.text.TextField();
		txt.defaultTextFormat = new flash.text.TextFormat("Courier New",null,fps_colour);
		txt.selectable = false;
		Lib.current.addChild(txt);
	}

	public function run(main:Float->Void) {
		pt = Lib.getTimer();
		(new haxe.Timer(0)).run = function() {
			var ct = Lib.getTimer();
			var dt = ct - pt;
			if(dt==0) return;

			if(fps==-1.0) fps = 1000/dt;
			else fps = fps*0.95 + 0.05*1000/dt;
			txt.text = "fps: "+Std.string(fps).substr(0,5);

			main(dt/1000);

			pt = ct;
		}
	}

}
