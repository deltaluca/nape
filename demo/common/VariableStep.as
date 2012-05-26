package {

	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.getTimer;
	import flash.utils.setInterval;
	import flash.display.Sprite;
	import flash.display.DisplayObjectContainer;

	public class VariableStep extends Sprite {
		private var fps:Number;
		private var pt:int;

		private var txt:TextField;

		public function VariableStep():void { fps = -1.0; }
		public function init_fps(stage:DisplayObjectContainer, fps_colour:uint=0xffffff):void {
			txt = new TextField();
			txt.defaultTextFormat = new TextFormat("Courier New",null,fps_colour);
			txt.selectable = false;
			stage.addChild(txt);
		}

		public function run(main:Function):void {
			pt = getTimer();
			setInterval(function():void {
				var ct:uint = getTimer();
				var dt:uint = ct - pt;
				if(dt==0) return;

				if(fps==-1.0) fps = 1000/dt;
				else fps = fps*0.95 + 0.05*1000/dt;
				txt.text = "fps: "+fps.toString().substr(0,5);

				main(dt/1000);

				pt = ct;
			},0);
		}
	}
}
