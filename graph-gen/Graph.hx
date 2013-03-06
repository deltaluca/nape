package;

import StringTools;

//import nme.display.BitmapData;
//import nme.display.Sprite;
//import nme.display.Bitmap;

import format.png.Writer;
import format.png.Reader;
import format.png.Tools;
import format.png.Data;

import sys.io.Process;

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

class RGBA {
    public var r:Float;
    public var g:Float;
    public var b:Float;
    public var a:Float;
    public function new(r, g, b, a) {
        this.r = r;
        this.g = g;
        this.b = b;
        this.a = a;
    }
    public static function from(rgb:Int) {
        var b = rgb&0xff;
        var g = (rgb>>8)&0xff;
        var r = (rgb>>16)&0xff;
        return new RGBA(r/0xff, g/0xff, b/0xff, 1);
    }
    public function toString() {
        var r = Std.int(this.r*0xff);
        var g = Std.int(this.g*0xff);
        var b = Std.int(this.b*0xff);
        var a = Std.int(this.a*0xff);
        var c = (a << 24) | (r << 16) | (g << 8) | b;
        return StringTools.hex(c, 8);
    }
}

class Graph {
    static var logv:Float;

    static function _vof(x:Float) return 0.8*(Math.log(x)*logv+Math.pow(x,0.7)/20);
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
//        nme.Lib.create(
//            main2,
//            660, 230,
//            60,
//            0xffffff,
//            nme.Lib.HARDWARE | nme.Lib.VSYNC,
//            "Graph"
//        );
        main2();
    }

    static function main2() {
        logv = 1/Math.log(Std.parseFloat(Sys.args()[0]));

        var don_str = sys.io.File.getContent("/home/luca/Projects/nape/donations.dat");
        var donations = Lambda.array(Lambda.map(don_str.split(","), function(x) return Std.parseFloat(StringTools.trim(x))));

        trace(bounds(donations,true));
        trace(bounds(donations,false));

        var input;
        var ifile = new Reader(input = sys.io.File.read("/home/luca/Projects/www.napephys.com/assets/graph.png", true));
        var idataf = ifile.read();
        input.close();
        var header = Tools.getHeader(idataf);
        var idata = Tools.extract32(idataf);
        var rgb = (function () {
            var ret = [];
            var input = new haxe.io.BytesInput(idata);
            for (y in 0...header.height) {
                var row = [];
                for (x in 0...header.width) {
                    var suc = false;
                    if (y > 29) {
                        if (x < 199 || (x > 340 && x < 550)) {
                            for (i in 0...4) row.push(new RGBA(0,0,0,0));
                            suc = true;
                        }
                    }

                    var b = input.readByte()/0xff;
                    var g = input.readByte()/0xff;
                    var r = input.readByte()/0xff;
                    var a = input.readByte()/0xff;
                    if (!suc) {
                        for (i in 0...4)
                            row.push(new RGBA(r, g, b, a));
                    }
                }
                for (i in 0...4) for (r in row) ret.push(r);
            }
            return ret;
        })();

        var width = header.width*4;
        var height = header.height*4;
        function __circle(x0:Int,y0:Int,radius:Int, col:RGBA) {
            function setpixel(xx, yy, col) {
                for (x in xx...xx+4) for (y in yy...yy+4) {
                    if (x < 0 || y < 0 || x>=width || y >=height) continue;
                    rgb[y*width + x] = col;
                }
            }
            if(radius==0) setpixel(x0,y0,col);
            else {
                if(radius==1) {
                    setpixel(x0,y0+1,col);
                    setpixel(x0,y0-1,col);
                    setpixel(x0+1,y0,col);
                    setpixel(x0-1,y0,col);
                    setpixel(x0-1,y0-1,col);
                    setpixel(x0-1,y0+1,col);
                    setpixel(x0+1,y0-1,col);
                    setpixel(x0+1,y0+1,col);
                }else {
                    var x = 0;
                    var y = radius;
                    var p = 3-2*radius;
                    while(y>=x) {

                        setpixel(x0+x,y0+y,col);
                        setpixel(x0+x,y0-y,col);
                        setpixel(x0-x,y0+y,col);
                        setpixel(x0-x,y0-y,col);
                        setpixel(x0+y,y0+x,col);
                        setpixel(x0+y,y0-x,col);
                        setpixel(x0-y,y0+x,col);
                        setpixel(x0-y,y0-x,col);

                        if(p<0) p += 6 + ((x++)<<2);
                        else    p += 10+ ((x++ - y--)<<2);
                    }
                }
            }
        }

        function __line(x0:Int,y0:Int,x1:Int,y1:Int, col:RGBA) {
            function setpixel(xx, yy, col) {
                for (x in xx...xx+4) for (y in yy...yy+4) {
                    if (x < 0 || y < 0 || x>=width || y >=height) continue;
                    rgb[y*width + x] = col;
                }
            }
            function draw(op1, op2, dx, dy) {
                var err = dx-dy;

                while(true) {
                    setpixel(x0, y0, col);

                    if(x0==x1 && y0==y1) break;

                    var e2 = err<<1;
                    if(e2>-dy) { err -= dy; x0=op1(x0); }
                    if(e2< dx) { err += dx; y0=op2(y0); }
                }
            };

            if(x0<x1) {
                var dx = x1-x0;
                if(y0<y1) {
                    var dy = y1-y0;
                    var off = width;
                    draw(function (x) return x+1, function (x) return x+1, dx, dy);
                }else {
                    var dy = y0-y1;
                    var off = -width;
                    draw(function (x) return x+1, function (x) return x-1, dx, dy);
                }
            }else {
                var dx = x0-x1;
                if(y0<y1) {
                    var dy = y1-y0;
                    var off = width;
                    draw(function (x) return x-1, function (x) return x+1, dx, dy);
                }else {
                    var dy = y0-y1;
                    var off = -width;
                    draw(function (x) return x-1, function (x) return x-1, dx, dy);
                }
            }
        }

        function wrap(a:Float) return if (a < 0) a + Math.PI*2 else a;

        function drawSector(x:Float, y:Float, radius:Float, a0:Float, a1:Float, col:RGBA) {
            if (a0 > a1) { var t = a0; a0 = a1; a1 = t; }
            var xmin = Math.floor(x+0.5 - radius);
            var ymin = Math.floor(y+0.5 - radius);
            var xmax = Math.ceil(x+0.5 + radius);
            var ymax = Math.ceil(y+0.5 + radius);
            if (xmin < 0) xmin = 0;
            if (ymin < 0) ymin = 0;
            if (xmax >= width) xmax = width-1;
            if (ymax >= height) ymax = height-1;
            for (j in ymin...(ymax+1)) {
                for (i in xmin...(xmax+1)) {
                    var dx = x - i - 0.5;
                    var dy = y - j - 0.5;
                    var d = Math.sqrt(dx*dx+dy*dy);
                    if (d > radius) continue;

                    var a = wrap(Math.atan2(-dy, -dx));
                    if (a < a0) continue;
                    if (a > a1) continue;

                    rgb[j*width + i] = col;
                }
            }
        }
        function drawCircle(x:Float, y:Float, radius:Float, thick:Float, col:RGBA) {
            __circle(Std.int(x+0.5), Std.int(y+0.5), Std.int(radius), col);
        }
        function drawLine(x0:Float, y0:Float, x1:Float, y1:Float, thick:Float, col:RGBA) {
            __line(Std.int(x0+0.5), Std.int(y0+0.5), Std.int(x1+0.5), Std.int(y1+0.5), col);
        }

//        var bit = new BitmapData(660,230,true,BitmapData.CLEAR);
//        var spr = new Sprite(); var g = spr.graphics;
//        nme.Lib.current.addChild(new Bitmap(bit,true));

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
//            g.lineStyle(0,0,0);
            for(p in pie) {
                var col = cols[ci++];
                drawSector(cx*2, cy*2, rr*2, wrap(cang), wrap(cang + p), RGBA.from(col));
                cang += p;

//                var cnt = Std.int(p/Math.PI)+1;
//                for(i in 0...cnt) {
//                    g.moveTo(cx,cy);
//                    g.beginFill(col,1);
//                    g.lineTo(cx+rr*Math.cos(cang),cy+rr*Math.sin(cang));
//                    var cnt2 = Std.int(p/cnt/(Math.PI*0.01))+1;
//                    for(j in 0...cnt2) {
//                        cang += p/cnt/cnt2;
//                        g.lineTo(cx+rr*Math.cos(cang),cy+rr*Math.sin(cang));
//                    }
//                    g.endFill();
//                }
            }

            drawCircle(cx*2, cy*2, rr*2, 2, new RGBA(0,0,0,1));

            var cang = 0.0;
            drawLine(cx*2,cy*2,(cx+rr*Math.cos(cang))*2,(cy+rr*Math.sin(cang))*2, 2, new RGBA(0,0,0,1));

            for(p in pie) {
                cang += p;
                drawLine(cx*2,cy*2,(cx+rr*Math.cos(cang))*2,(cy+rr*Math.sin(cang))*2, 1, new RGBA(0,0,0,1));
            }

//            var txt = new nme.text.TextField();
//            var tf = new nme.text.TextFormat(null,20);
//            txt.defaultTextFormat = tf;
//            txt.x = xv+20;
//            txt.y = 2;
//            txt.width = 300;
//            txt.text = title;
//
//            bit.draw(txt, txt.transform.matrix);
//
            var cx = xv*2+410;
            for(i in 0...maxi+1) {
                var yc = 30+i*40+30*2;
//                g.beginFill(cols[i],1);
//                g.drawRect(cx,yc,50,25);
//                g.endFill();
//
//                var txt = new nme.text.TextField();
//                var tf = new nme.text.TextFormat(null,12);
//                txt.defaultTextFormat = tf;
//                txt.x = (cx+55)/2;
//                txt.y = yc/2-2;
//                if(i==0) txt.text = "£[0,"+ivof(0)+"]";
//                else txt.text = "£("+ivof(i-1)+","+ivof(i)+"]";
//
//                bit.draw(txt, txt.transform.matrix);
            }
        }

        draw(0,function(x) return x, "Sum value of donations");
        draw(350,function(x) return 1, "Number of donations");

//        bit.draw(spr, new nme.geom.Matrix(0.5,0,0,0.5,0,0));

/*        var odata = new haxe.io.BytesOutput();
        for (y in 0...header.height*4) {
        for (x in 0...header.width*4) {
            var dat = rgb[y*4*header.width + x];
            odata.writeByte(Std.int(0xff*dat.a));
            odata.writeByte(Std.int(0xff*dat.b));
            odata.writeByte(Std.int(0xff*dat.g));
            odata.writeByte(Std.int(0xff*dat.r));
        }}
        var data = Tools.build32BE(header.width*4, header.height*4, odata.getBytes());*/

        var odata = new haxe.io.BytesOutput();
        for (y in 0...header.height) {
        for (x in 0...header.width) {
            var dat = new RGBA(0, 0, 0, 0);
            for (i in 0...4) {
            for (j in 0...4) {
                var elt = rgb[(4*y + j)*(4*header.width) + (4*x + i)];
                dat.r += elt.r/16;
                dat.g += elt.g/16;
                dat.b += elt.b/16;
                dat.a += elt.a/16;
            }}
            odata.writeByte(Std.int(0xff*dat.a));
            odata.writeByte(Std.int(0xff*dat.r));
            odata.writeByte(Std.int(0xff*dat.g));
            odata.writeByte(Std.int(0xff*dat.b));
        }}
        var data = Tools.build32BE(header.width, header.height, odata.getBytes());

        var fname = "/home/luca/Projects/www.napephys.com/assets/graph.png";
        var fout = sys.io.File.write(fname, true);
        var writer = new Writer(fout);
        writer.write(data);
        trace("written to "+fname);
        new Process("display", [fname]);
    }
}
