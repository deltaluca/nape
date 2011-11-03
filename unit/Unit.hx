package;

class Unit {
	static function main() {
		var r = new haxe.unit.TestRunner();
		r.add(new UVec2());
		r.add(new UAABB());

		r.add(new UCircle());
		r.add(new UPolygon());
	#if cpp
		cpp.Sys.exit(r.run()?0:1);
	#else
		r.run();
	#end
	}
}


