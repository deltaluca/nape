package;

import nape.geom.Vec2;
import nape.shape.Circle;
import nape.phys.Body;

class UCircle extends haxe.unit.TestCase {

	public function testBasic() {
		var c = new Circle(10);
		assertEquals(10.0, c.radius);

		c.radius += 10;
		assertEquals(20.0, c.radius);
		
		assertEquals(0.0, c.localCOM.x);
		assertEquals(0.0, c.localCOM.y);

		c.localCOM.addeq(Vec2.get(10,20));
		assertEquals(10.0, c.localCOM.x);
		assertEquals(20.0, c.localCOM.y);

		c = new Circle(1, Vec2.get(1,2));
		assertEquals(1.0, c.radius);
		assertEquals(1.0, c.localCOM.x);
		assertEquals(2.0, c.localCOM.y);
	}

	public function testProperties() {
		var c = new Circle(10);
		assertEquals(100*Math.PI, c.area);
		assertEquals(0.5*100, c.inertia);

		c.localCOM = Vec2.get(1,2);
		assertEquals(100*Math.PI, c.area);
		assertEquals(0.5*100 + 5, c.inertia);
	}

	public function testBodyMix() {
		var b = new Body();
		var c = new Circle(10);
		c.body = b;

		assertEquals(-10.0, c.bounds.x);
		assertEquals(-10.0, c.bounds.x);
		assertEquals(20.0, c.bounds.width);
		assertEquals(20.0, c.bounds.height);

		c.localCOM.x += 10;
		assertEquals(0.0, c.bounds.x);
		assertEquals(20.0, c.bounds.width);
	}

}
