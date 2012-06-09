package {
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.getTimer;
	import flash.utils.setInterval;

	public class FixedStep extends Sprite {
		private var fps:Number;
		private var ideal:Number;

		private var pt:uint;
		private const timeout:uint = 100;

		private var txt:TextField;

		public function FixedStep() {}
		public function init_fps(stage:DisplayObjectContainer, ideal:Number,fps_colour:uint=0xffffff):void {
			this.ideal = 1000*ideal;
			fps = -1.0;

			txt = new TextField();
			txt.defaultTextFormat = new TextFormat("Courier New",null,fps_colour);
			txt.selectable = false;
			stage.addChild(txt);
		}

		public function run(main:Function):void {
			pt = getTimer();
			var del:Function = function():void {
				var ct:uint = getTimer();
				var dt:uint = ct-pt;
				if(dt==0) return;
				if(dt>timeout) dt = timeout;
		
				if(fps==-1.0) fps = 1000/dt;
				else fps = fps*0.95 + 0.05*1000/dt;
				txt.text = "fps: "+fps.toString().substr(0,5);

				var steps:uint = uint(Math.round(dt/ideal));
				for(var i:uint = 0; i<steps; i++)
					main(ideal/1000);

				var delta:uint = dt-uint(steps*ideal);
				pt = ct - delta;
			}
			setInterval(del,1);
			del(ideal/1000);
		}
	}
}
