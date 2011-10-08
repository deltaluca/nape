package;

import nape.geom.AABB;

class Unit {
	static function main() {
		var r = new haxe.unit.TestRunner();
		r.add(new UVec2());
		r.add(new UAABB());

		r.add(new UCircle());
		cpp.Sys.exit(r.run()?0:1);
	}
}


