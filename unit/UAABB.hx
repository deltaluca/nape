package;

import nape.geom.AABB;
import nape.geom.Vec2;
class UAABB extends haxe.unit.TestCase {

	public function testBasic() {
		var a = new AABB();
		assertEquals(0.0,a.x);
		assertEquals(0.0,a.y);
		assertEquals(0.0,a.width);
		assertEquals(0.0,a.height);
		assertEquals(0.0,a.min.x);
		assertEquals(0.0,a.max.x);
		assertEquals(0.0,a.min.y);
		assertEquals(0.0,a.max.y);

		a.width = 100;
		assertEquals(100.0,a.width);
		assertEquals(100.0,a.max.x);

		a.height = 50;
		assertEquals(50.0,a.height);
		assertEquals(50.0,a.max.y);

		a.x -= 50;
		a.y -= 50;
		assertEquals(-50.0, a.x);
		assertEquals(-50.0, a.y);
		assertEquals(-50.0, a.min.x);
		assertEquals(-50.0, a.min.y);
		assertEquals(100.0, a.width);
		assertEquals(50.0, a.max.x);
		assertEquals(0.0, a.max.y);

		a.max.x = 100.0;
		assertEquals(100.0, a.max.x);
		assertEquals(150.0, a.width);

		a.min.x = 50.0;
		assertEquals(50.0, a.x);
		assertEquals(50.0, a.width);
	}

	public function testCopy() {
		var a = new AABB(1,2,3,4);
		var b = a.copy();
		assertEquals(1.0, b.x);
		assertEquals(2.0, b.y);
		assertEquals(3.0, b.width);
		assertEquals(4.0, b.height);
	}

	public function testVec2Mix() {
		var a = new AABB();
		a.min.subeq(Vec2.get(20,30));

		assertEquals(-20.0, a.x);
		assertEquals(-30.0, a.y);
		assertEquals(20.0, a.width);
		assertEquals(30.0, a.height);
	}

}
