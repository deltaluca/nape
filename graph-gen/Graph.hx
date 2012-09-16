package;

import StringTools;

import nme.display.BitmapData;
import nme.display.Sprite;
import nme.display.Bitmap;

import format.png.Writer;
import format.png.Tools;
import format.png.Data;

class Simplex {
	var reads:Array<Float>; //first row
	var table:Array<Array<Float>>; //row, then column of rest
	var targs:Array<Float>; //last column
	var result:Float;

	//   <-xs-> <-ss->   V
	// ----------------------
	// 1 <---reads---> result
    // 0 <----------->   ^
    // 0 <---table---> targs
    // 0 <----------->   v

	var vars:Int;
	var slacks:Int;
	public function new(vars:Int,slacks:Int) {
		table = new Array<Array<Float>>();
		reads = new Array<Float>();
		targs = new Array<Float>();
		result = 0.0;

		this.vars = vars;
		this.slacks = slacks;
	}

	public function maximise(mults:Array<Float>) {
		if(mults.length!=vars) throw "....";
		for(i in 0...vars) reads[i] = mults[i];
		for(i in 0...slacks) reads[i+vars] = 0.0;
	}

	public function subjectto(mults:Array<Float>,target:Float) {
		if(mults.length!=vars+slacks) throw "....";
		var xs = new Array<Float>();
		for(i in 0...vars+slacks) xs.push(mults[i]);
		targs.push(target);
		table.push(xs);
	}

	public function run() {
		function clamp(x:Float) {
			return if(x*x < 1e-5) 0 else x;
		}
		function pivot(piv,col) {
			//normalise pivot row
			var val = table[piv][col];
			for(i in 0...vars+slacks)
				table[piv][i] /= val;
			targs[piv] /= val;
			table[piv][col] = 1.0;

			//pivot rest of the rows
			function pivot(row:Array<Float>,targ:Float):Float {
				if(row[col]!=0) {
					var mul = -row[col];
					for(j in 0...vars+slacks) {
						row[j] = clamp(row[j]+mul*table[piv][j]);
					}
					row[col] = 0.0;
					return clamp(targ + mul*targs[piv]);
				}else return targ;
			}
			result = pivot(reads,result);
			for(i in 0...table.length) {
				if(i==piv) continue;
				targs[i] = pivot(table[i],targs[i]);
			}
		}
		function value(val:Int) {
			var onenzero = 0;
			var row = -1;
			for(i in 0...table.length) {
				var k = table[i][val];
				if(k!=0) {
					onenzero++;
					if(onenzero>1) break;
					row = i;
				}
			}
			if(onenzero==1) {
				return targs[row] / table[row][val];
			}else
				return Math.NaN;
		}

		var stars = [];
		function starsof(stars) {
			for(i in 0...table.length) stars[i] = false;

			var any = false;
			for(col in 0...vars+slacks) {
				if(value(col)<0) {
					var row = -1;
					for(i in 0...table.length) {
						if(table[i][col]!=0) {
							row = i;
							break;
						}
					}
					stars[row] = true;
					any = true;
				}
			}
			return any;
		}

		while(starsof(stars)) {
			var row = -1;
			for(i in 0...stars.length) {
				if(stars[i]) {
					row = i;
					break;
				}
			}

			//find col with max entry
			var col = -1;
			var max = Math.NEGATIVE_INFINITY;
			for(i in 0...vars+slacks) {
				if(table[row][i]>max) {
					max = table[row][i];
					col = i;
				}
			}

			//find pivot
			var piv = -1;
			var val = Math.POSITIVE_INFINITY;
			for(i in 0...table.length) {
				if(table[i][col]>0) {
					var ival = targs[i] / table[i][col];
					if(ival<val || (ival==val && stars[i] && !stars[piv])) {
						val = ival;
						piv = i;
					}
				}
			}

			pivot(piv,col);
		}

		while(true) {
			var col = -1;
			//find negative reads
			for(i in 0...vars+slacks) {
				if(reads[i]<0) {
					col = i;
					break;
				}
			}
			if(col==-1) break;

			var piv = -1;
			var val = Math.POSITIVE_INFINITY;
			//find pivot
			for(i in 0...table.length) {
				if(table[i][col]>0) {
					var ival = targs[i] / table[i][col];
					if(ival<val) {
						val = ival;
						piv = i;
					}
				}
			}
			if(piv==-1) {
				throw "fuuuuuu";
				break;
			}

			pivot(piv,col);
		}

		var ret = [];
		for(i in 0...vars)
			ret.push(value(i));
		return [result].concat(ret);
	}
}

class Graph {
	static var logv:Float;

	static function _vof(x:Float) return 0.8*(Math.log(x)*logv+Math.pow(x,0.7)/20)
	static function _ivof(xin:Float) {
		var x = 0.0;
		var y = 10000.0;
		var vx = _vof(x)-xin;
		var vy = _vof(y)-xin;
		for(i in 0...1000) {
			if(vx*vy <= 0) {
				var m = (x+y)/2;
				var vm = _vof(m)-xin;
				if(vm*vx<=0) {
					y = m;
					vy = vm;
				}else {
					x = m;
					vx = vm;
				}
			}
		}
		return (x+y)/2;
	}

	static var ivs:Array<Float> = [];
	static function vof(x:Float) {
		var i = 0;
		while(i==ivs.length || x>ivs[i]) {
			if(i==ivs.length) ivs.push(Std.int(_ivof(i+1)));
			if(x>ivs[i]) i++;
		}
		return i;
	}
	static function ivof(i:Int) {
		if(i==-1) return 0.0;
		else {
			while(i>=ivs.length)
				ivs.push(Std.int(_ivof(ivs.length+1)));
			return ivs[i];
		}
	}

	public static function bounds(donations:Array<Float>, min:Bool) {
		var bounds = [];
		var total = 0.0;
		for(d in donations) {
			total += d;

			var i = vof(d);
			while(i>=bounds.length) {
				var j = bounds.length;
				bounds.push({min:if(j==0) 0 else ivof(j-1), max:ivof(j), cnt:0, perc:0.0, total:0.0});
			}

			bounds[i].cnt++;
			bounds[i].total += d;
		}

		//transform bounds
		var i = 0;
		while(i<bounds.length) {
			var b = bounds[i];
			if(b.cnt==0) {
				cpp.Lib.println("Range: min="+b.min+"->"+b.max+" excluded for 0 donations in simplex");
				bounds[i] = bounds[bounds.length-1];
				bounds.pop();
				continue;
			}
			i++;
			b.min *= b.cnt;
			b.max *= b.cnt;
			b.perc = if(b.total==0) 0.0 else b.total / total;
		}

		var simplex = new Simplex(bounds.length,bounds.length*2);
		var nones:Array<Float> = []; for(i in 0...bounds.length) nones.push(min ? 1.0 : -1.0);
		simplex.maximise(nones);
		for(i in 0...bounds.length) {
			var ones:Array<Float> = [];
			for(j in 0...bounds.length) ones.push(if(i==j) 1.0 else 0.0);
			for(j in 0...bounds.length) ones.push(if(i==j) 1.0 else 0.0);
			for(j in 0...bounds.length) ones.push(0.0);
			simplex.subjectto(ones,bounds[i].max);

			ones = [];
			for(j in 0...bounds.length) ones.push(if(i==j) 1.0 else 0.0);
			for(j in 0...bounds.length) ones.push(0.0);
			for(j in 0...bounds.length) ones.push(if(i==j) -1.0 else 0.0);
			simplex.subjectto(ones,bounds[i].min);
		}

		nones = [];
		for(i in 0...bounds.length) nones.push(bounds[i].perc==0 ? 0 : 1/bounds[i].perc - bounds.length);
		for(i in 0...bounds.length) { nones.push(0); nones.push(0); }
		simplex.subjectto(nones,0);

		var results = simplex.run();
		for(i in 0...bounds.length) {
			results[i+1] = if(bounds[i].cnt==0) 0 else results[i+1]/bounds[i].cnt;
		}

		return {
			total: (min ? -1 : 1) * results[0],
			ranges: results.slice(1)
		};
	}

	public static function main() {
        nme.Lib.create(
            main2,
            660, 230,
            60,
            0xffffff,
            nme.Lib.HARDWARE | nme.Lib.VSYNC,
            "Graph"
        );
    }

    static function main2() {
		logv = 1/Math.log(Std.parseFloat(cpp.Sys.args()[0]));

		var don_str = cpp.io.File.getContent("/home/luca/Projects/nape/donations.dat");
		var donations = Lambda.array(Lambda.map(don_str.split(","), function(x) return Std.parseFloat(StringTools.trim(x))));

		trace(bounds(donations,true));
		trace(bounds(donations,false));

		var bit = new BitmapData(660,230,true,BitmapData.CLEAR);
		var spr = new Sprite(); var g = spr.graphics;
		nme.Lib.current.addChild(new Bitmap(bit,true));

		function draw(xv, value, title) {
			var pie:Array<Float> = [];
			var total = 0.0;

			var maxi = 0;
			for(d in donations) {
				var i = vof(d);
				if(i>maxi) maxi = i;
				total += value(d);
			}
			for(i in 0...maxi) pie.push(0.0);

			for(d in donations) {
				var i = vof(d);
				if(i<0) i = 0;

				pie[i]+=value(d);
			}
			for(i in 0...pie.length) {
				pie[i] *= Math.PI*2/total;
			}


			var rr = 97*2;
			var cx = xv*2+200;
			var cy = 200+30*2;

			var cols = [0xff0000,0xffff00,0xff00,0xffff,0xff,0xff00ff,0xff8000];

			var ci = 0;
			var cang = 0.0;
			g.lineStyle(0,0,0);
			for(p in pie) {
				var col = cols[ci++];
				var cnt = Std.int(p/Math.PI)+1;
				for(i in 0...cnt) {
					g.moveTo(cx,cy);
					g.beginFill(col,1);
					g.lineTo(cx+rr*Math.cos(cang),cy+rr*Math.sin(cang));
					var cnt2 = Std.int(p/cnt/(Math.PI*0.01))+1;
					for(j in 0...cnt2) {
						cang += p/cnt/cnt2;
						g.lineTo(cx+rr*Math.cos(cang),cy+rr*Math.sin(cang));
					}
					g.endFill();
				}
			}

			g.lineStyle(2,0,1);
			g.drawCircle(cx,cy,rr);

			var cang = 0.0;
			g.moveTo(cx,cy);
			g.lineTo(cx+rr*Math.cos(cang),cy+rr*Math.sin(cang));

			for(p in pie) {
				cang += p;
				g.moveTo(cx,cy);
				g.lineTo(cx+rr*Math.cos(cang),cy+rr*Math.sin(cang));
			}

			var txt = new nme.text.TextField();
			var tf = new nme.text.TextFormat(null,20);
			txt.defaultTextFormat = tf;
			txt.x = xv+20;
			txt.y = 2;
			txt.width = 300;
			txt.text = title;

			bit.draw(txt);

			var cx = xv*2+410;
			for(i in 0...maxi+1) {
				var yc = 30+i*40+30*2;
				g.beginFill(cols[i],1);
				g.drawRect(cx,yc,50,25);
				g.endFill();

				var txt = new nme.text.TextField();
				var tf = new nme.text.TextFormat(null,12);
				txt.defaultTextFormat = tf;
				txt.x = (cx+55)/2;
				txt.y = yc/2-2;
				if(i==0) txt.text = "£[0,"+ivof(0)+"]";
				else txt.text = "£("+ivof(i-1)+","+ivof(i)+"]";

				bit.draw(txt);
			}
		}

		draw(0,function(x) return x, "Sum value of donations");
		draw(350,function(x) return 1, "Number of donations");

		bit.draw(spr, new nme.geom.Matrix(0.5,0,0,0.5,0,0));

		var data = Tools.build32BE(660,230,bit.getPixels(bit.rect));
		var fout = cpp.io.File.write("/home/luca/Projects/napephys.com/assets/graph.png",true);
		var writer = new Writer(fout);
		writer.write(data);
		trace("written to /home/luca/Projects/napephys.com/assets/graph.png");
	}
}
