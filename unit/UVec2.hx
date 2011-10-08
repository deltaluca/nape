package;

import nape.geom.Vec2;
class UVec2 extends haxe.unit.TestCase {

	public function valid(x:Vec2) {
		var ret = true;
		try { 
			x.x = x.x;
		}catch(e:Dynamic) {
			ret = false;
		}
		return ret;
	}
	public function testPooling() {
		for(i in 0...10) {
			var a = Vec2.get(10,20);
			a = new Vec2();
			assertTrue(valid(a));

			a.dispose();
			assertFalse(valid(a));
		}
	}

	public function testBasic() {
		var a = Vec2.get(10,20);
		assertEquals(10.0,a.x);
		assertEquals(20.0,a.y);

		a.setxy(20,10);
		assertEquals(20.0,a.x);
		assertEquals(10.0,a.y);

		a.x += a.y;
		assertEquals(30.0,a.x);
		a.y = -a.x;
		assertEquals(-30.0,a.y);

		var b = Vec2.get(40,50);
		a.set(b);
		assertEquals(40.0,a.x);
		assertEquals(50.0,a.y);

		var c = a.copy();
		assertEquals(c.x,a.x);
		assertEquals(c.y,a.y);

		c.x = 20;
		assertEquals(40.0,a.x);
		assertEquals(20.0,c.x);

		a = Vec2.get();
		assertEquals(0.0,a.x);
		assertEquals(0.0,a.y);

		a = new Vec2();
		assertEquals(0.0,a.x);
		assertEquals(0.0,a.y);
	}

	public function testPolar() {
		var a = Vec2.fromPolar(0.5,0.5);
		assertEquals(a.length, 0.5);
		assertEquals(a.angle, 0.5);

		a.length *= a.length;
		assertEquals(a.length, 0.25);
		assertEquals(a.angle, 0.5);

		a.angle += a.length;
		assertEquals(a.length, 0.25);
		assertEquals(a.angle, 0.75);

		assertEquals(0.25*Math.cos(0.75), a.x);
		assertEquals(0.25*Math.sin(0.75), a.y);

		assertEquals(a.lsq(),0.0625);
	}

	public function testSimpleArithmetic() {
		var a = Vec2.get(10,20);
		var b = Vec2.get(30,40);

		var c = a.add(b);
		assertEquals(40.0,c.x);
		assertEquals(60.0,c.y);

		var c = a.sub(b);
		assertEquals(-20.0,c.x);
		assertEquals(-20.0,c.y);

		var d = a.dot(b);
		assertEquals(1100.0,d);

		var d = a.cross(b);
		assertEquals(-200.0,d);

		var c = a.mul(10);
		assertEquals(100.0,c.x);
		assertEquals(200.0,c.y);

		a.addeq(b);
		assertEquals(40.0,a.x);
		assertEquals(60.0,a.y);

		a.subeq(b);
		assertEquals(10.0,a.x);
		assertEquals(20.0,a.y);

		a.muleq(10);
		assertEquals(100.0,a.x);
		assertEquals(200.0,a.y);
	}
}
