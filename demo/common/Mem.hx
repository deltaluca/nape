package;

import flash.display.Bitmap;
import flash.display.Sprite;
import flash.Lib;
import flash.display.BitmapData;
import flash.geom.Rectangle;

class Mem extends Sprite {
	public function new(width:Int, height:Int, minmem:Float, maxmem:Float, bg:Int, colour:Int, maxcol:Int) {
		var col = 0;
		var bmp = new BitmapData(width,height,true,bg);
		super();
		addChild(new Bitmap(bmp));
		var alpha = bg>>>24;

		var txt = new flash.text.TextField();
		txt.defaultTextFormat = new flash.text.TextFormat(null,null,~bg,null,null,null,null,null,flash.text.TextFormatAlign.RIGHT);
		txt.width = width;
		txt.selectable = false;
		addChild(txt);

		var faded = (colour&0xfefefefe)>>>1;
		function fill(y:Int,fy:Float,colour:Int) {
			if(y<0 || y>=height) return;
			var src = bmp.getPixel32(col,y);

			var da = Std.int((colour>>>24)*fy);
			var dr = (colour>>>16)&0xff;
			var dg = (colour>>>8 )&0xff;
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

		function render(mem:Float, colour:Int) {
			mem /= (1024*1024);

			var y = (height-1) - (mem-minmem)/(maxmem-minmem)*height;
			var iy = Std.int(y); var fy = y-iy;
			fill(iy, 1-fy, colour);
			fill(iy+1, fy, colour);
		}

		var rect = new Rectangle(0,0,1,height);
		(new haxe.Timer(0)).run = function() {
			rect.x = col;
			bmp.fillRect(rect,bg);

			var priv = flash.system.System.privateMemory;
			var used = flash.system.System.totalMemoryNumber;
			render(priv,maxcol);
			render(used,colour);

			txt.text = "private: "+Std.string(Std.int(priv/1024/1024*100)/100)+"MB"
			        + " total: "+Std.string(Std.int(used/1024/1024*100)/100)+"MB";
			
			col = (col+1)%width;
		}
	}
}
