package;

import nape.geom.MarchingSquares;
import nape.geom.Vec2;
import nape.geom.AABB;
import nape.geom.GeomPoly;

import nape.util.ShapeDebug;
import flash.display.StageQuality;

import VariableStep;
import FPS;

class PerlinSquares extends VariableStep {
	static function main() {
        #if nme
            nme.Lib.create(
                function() { new PerlinSquares(); },
                400, 300,
                60,
                0x333333,
                nme.Lib.HARDWARE | nme.Lib.VSYNC,
                "PerlinSquares"
            );
        #else
    		new PerlinSquares();
        #end
	}

	function new() {
		super(0);
		Perlin3D.init_noise();

		var debug = new ShapeDebug(400,300,0xffffff);
		addChild(debug.display);
		stage.quality = StageQuality.LOW;

		//iso-surface function.
		var z = 0.0;
		var bnd = 0.0;
		var iso = function(x:Float,y:Float) return Perlin3D.noise(x/40,y/30,z)-bnd;

		//parameters
		var combine = true;
		var cellsize = Vec2.get(10,10);
		var gridsize = Vec2.get(100,100);
		var quality = 2;

		var bounds = new AABB(0,0,400,300);

		run(function(dt) {
			debug.clear();

			z += dt;
			bnd = 0.35*Math.cos(0.3*z);

			var polys = MarchingSquares.run(iso, bounds, cellsize, quality, gridsize, combine);
			for(p in polys) {
				var qs = p.convex_decomposition();
				for(q in qs) debug.drawFilledPolygon(q, colour(q));
				debug.drawPolygon(p, 0);
			}

			debug.flush();
		});
	}

	static inline function colour(p:GeomPoly) {
        //hue
        var h = p.area()/3000*360; while(h>360) h -= 360;
        var f = (h%60)/60;

        var r:Float, g:Float, b:Float;
        if     (h<=60 ) { r = 1; g = f; b = 0; }
        else if(h<=120) { r = 1-f; g = 1; b = 0; }
        else if(h<=180) { r = 0; g = 1; b = f; }
        else if(h<=240) { r = 0; g = 1-f; b = 1; }
        else if(h<=300) { r = f; g = 0; b = 1; }
        else            { r = 1; g = 0; b = 1-f; }

        return (Std.int(r*0xff)<<16)|(Std.int(g*0xff)<<8)|Std.int(b*0xff);
    }
}

class Perlin3D {
    public static inline function noise(x:Float, y:Float, z:Float) {
        var X = Std.int(x); x -= X; X &= 0xff;
        var Y = Std.int(y); y -= Y; Y &= 0xff;
        var Z = Std.int(z); z -= Z; Z &= 0xff;
        var u = fade(x); var v = fade(y); var w = fade(z);
        var A = p(X)  +Y; var AA = p(A)+Z; var AB = p(A+1)+Z;
        var B = p(X+1)+Y; var BA = p(B)+Z; var BB = p(B+1)+Z;
        return lerp(w, lerp(v, lerp(u, grad(p(AA  ), x  , y  , z   ),
                                       grad(p(BA  ), x-1, y  , z   )),
                               lerp(u, grad(p(AB  ), x  , y-1, z   ),
                                       grad(p(BB  ), x-1, y-1, z   ))),
                       lerp(v, lerp(u, grad(p(AA+1), x  , y  , z-1 ),
                                       grad(p(BA+1), x-1, y  , z-1 )),
                               lerp(u, grad(p(AB+1), x  , y-1, z-1 ),
                                       grad(p(BB+1), x-1, y-1, z-1 ))));
    }

    static inline function fade(t:Float) return t*t*t*(t*(t*6-15)+10)
    static inline function lerp(t:Float, a:Float, b:Float) return a + t*(b-a)
    static inline function grad(hash:Int, x:Float, y:Float, z:Float) {
        var h = hash&15;
        var u = h<8 ? x : y;
        var v = h<4 ? y : h==12||h==14 ? x : z;
        return ((h&1) == 0 ? u : -u) + ((h&2) == 0 ? v : -v);
    }

    static inline function p(i:Int) return perm[i]
    static var perm:#if flash10 flash.Vector<Int> #else Array<Int> #end;

    public static function init_noise() {
        #if flash10
    		perm = new flash.Vector<Int>(512,true);
        #else
            perm = new Array<Int>();
        #end

        var p = [151,160,137,91,90,15,
        131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
        190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
        88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,
        77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
        102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196,
        135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123,
        5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
        223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,
        129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
        251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
        49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
        138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180];

        for(i in 0...256) {
            perm[i]=    p[i];
            perm[256+i]=p[i];
        }
    }
}
