package;

import flash.display.Bitmap;
import flash.Lib;
import flash.display.BitmapData;
import flash.geom.Rectangle;

class FPS extends Bitmap {
	public function new(width:Int, height:Int, minfps:Float,maxfps:Float, bg:Int, colour:Int, linecol:Int) {
		var pt = Lib.getTimer();
		var sfps = 0.5*(minfps+maxfps);

		var col = 0;
		var bmp = new BitmapData(width,height,true,bg);
		super(bmp);
		var alpha = bg>>>24;

		var faded = (colour&0xfefefefe)>>>1;

		function fill(y:Int,fy:Float,colour:Int) {
			if(y<0 || y>=height) return;
			var src = bmp.getPixel32(col,y);	

			var da = Std.int((colour>>>24)*fy);
			var dr = (colour>>>16)&0xff;
			var dg = (colour>>>8)&0xff;
			var db = colour&0xff;
			
			var sa = src>>>24;
			var sr = (src>>>16)&0xff;
			var sg = (src>>>8)&0xff;
			var sb = src&0xff;

			var oa = Std.int(sa + da*(0xff-sa)/0xff/0xff);
			var or = Std.int((sr*sa/0xff + dr*(0xff-sa)*da/0xff/0xff)/oa*0xff);
			var og = Std.int((sg*sa/0xff + dg*(0xff-sa)*da/0xff/0xff)/oa*0xff);
			var ob = Std.int((sb*sa/0xff + db*(0xff-sa)*da/0xff/0xff)/oa*0xff);

			bmp.setPixel32(col,y,(oa<<24)|(or<<16)|(og<<8)|ob);
		}

		function render(fps:Float,colour:Int) {
			var y = (height-1) - (fps - minfps)/(maxfps-minfps)*height;
			var iy = Std.int(y); var fy = y-iy;
			fill(iy, 1-fy,colour);
			fill(iy+1, fy,colour);
		}

		for(x in 0...width) {
			col = x;
			for(i in 0...12)
				render(i*10,linecol);
		}	

		var rect = new Rectangle(0,0,1,height);
		(new haxe.Timer(0)).run = function() {
			var ct = Lib.getTimer();
			var fps = 1000/(ct-pt);
			sfps = sfps*0.95 + fps*0.05;
			pt = ct;

			rect.x = col;
			bmp.fillRect(rect,bg);

			for(i in 0...12)
				render(i*10,linecol);

			render(fps,faded);
			render(sfps,colour);

			col = (col+1)%width;	
		}
	}
}
