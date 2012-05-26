package {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	import flash.utils.setInterval;

	public class FPS extends Bitmap {
		public function FPS(width:uint, height:uint, minfps:Number,maxfps:Number, bg:uint, colour:uint, linecol:uint) {
			var bmp:BitmapData;
			super(bmp = new BitmapData(width,height,true,bg));

			var pt:uint = getTimer();
			var sfps:Number = 0.5*(minfps+maxfps);

			var col:uint = 0;
			var alpha:uint = bg>>>24;

			var faded:uint = (colour&0xfefefefe)>>>1;

			var fill:Function = function(y:int,fy:Number,colour:int):void {
				if(y<0 || y>=height) return;
				var src:uint = bmp.getPixel32(col,y);	

				var da:uint = uint((colour>>>24)*fy);
				var dr:uint = (colour>>>16)&0xff;
				var dg:uint = (colour>>>8)&0xff;
				var db:uint = colour&0xff;
				
				var sa:uint = src>>>24;
				var sr:uint = (src>>>16)&0xff;
				var sg:uint = (src>>>8)&0xff;
				var sb:uint = src&0xff;

				var oa:uint = uint(sa + da*(0xff-sa)/0xff/0xff);
				var or:uint = uint((sr*sa/0xff + dr*(0xff-sa)*da/0xff/0xff)/oa*0xff);
				var og:uint = uint((sg*sa/0xff + dg*(0xff-sa)*da/0xff/0xff)/oa*0xff);
				var ob:uint = uint((sb*sa/0xff + db*(0xff-sa)*da/0xff/0xff)/oa*0xff);

				bmp.setPixel32(col,y,(oa<<24)|(or<<16)|(og<<8)|ob);
			}

			var render:Function = function(fps:Number,colour:int):void {
				var y:Number = (height-1) - (fps - minfps)/(maxfps-minfps)*height;
				var iy:int = int(y); var fy:Number = y-iy;
				fill(iy, 1-fy,colour);
				fill(iy+1, fy,colour);
			}

			for(var x:uint = 0; x<width; x++) {
				col = x;
				for(var i:uint = 0; i<12; i++)
					render(i*10,linecol);
			}	

			var rect:Rectangle = new Rectangle(0,0,1,height);
			setInterval(function():void {
				var ct:uint = getTimer();
				var fps:Number = 1000/(ct-pt);
				sfps = sfps*0.95 + fps*0.05;
				pt = ct;

				rect.x = col;
				bmp.fillRect(rect,bg);

				for(var i:uint = 0; i<12; i++)
					render(i*10,linecol);

				render(fps,faded);
				render(sfps,colour);

				col = (col+1)%width;	
			},0);
		}
	}
}
