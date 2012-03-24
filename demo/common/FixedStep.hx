package;

import flash.Lib;

class FixedStep extends flash.display.Sprite {
	var fps:Float;
	var ideal:Float;

	var pt:Int;
	static inline var timeout:Int = 100;

	var txt:flash.text.TextField;

	public function new(ideal:Float,?fps_colour=0xffffff) {
		super();
		Lib.current.addChild(this);

		this.ideal = 1000*ideal;
		fps = -1.0;

		txt = new flash.text.TextField();
		txt.defaultTextFormat = new flash.text.TextFormat("Courier New",null,fps_colour);
		txt.selectable = false;
		Lib.current.addChild(txt);
	}

	public function run(main:Float->Void) {
		pt = Lib.getTimer();
		function del() {
			var ct = Lib.getTimer();
			var dt = ct - pt;
			if(dt==0) return;
			if(dt>timeout) dt = timeout;

			if(fps==-1.0) fps = 1000/dt;
			else fps = fps*0.95 + 0.05*1000/dt;
			txt.text = "fps: "+Std.string(fps).substr(0,5);

			var steps = Math.round(dt/ideal);
			for(i in 0...steps)
				main(ideal/1000);

			var delta = dt - Std.int(steps*ideal);
			pt = ct - delta;
		};
		(new haxe.Timer(1)).run = del;
		main(ideal/1000);
	}

}
