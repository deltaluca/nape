package;

import nape.geom.Vec2;
import nape.shape.Polygon;
import nape.geom.GeomPoly;
import nape.phys.Body;

class UPolygon extends haxe.unit.TestCase {

	public function testFactories() {
		var p = new Polygon(Polygon.box(20,40));
		assertEquals(800.0, p.area);
		var gp = new GeomPoly(p.localVerts);
		var ab = gp.bounds();
		assertEquals(-10.0, ab.x);
		assertEquals(-20.0, ab.y);
		assertEquals(20.0, ab.width);
		assertEquals(40.0, ab.height);

		var p = new Polygon(Polygon.rect(10,20,30,40));
		assertEquals(1200.0, p.area);
		var gp = new GeomPoly(p.localVerts);
		var ab = gp.bounds();
		assertEquals(10.0, ab.x);
		assertEquals(20.0, ab.y);
		assertEquals(30.0, ab.width);
		assertEquals(40.0, ab.height);

		var p = new Polygon(Polygon.regular(20.0,20.0,5));
		var darea = 0.5*5*10*10*Math.sin(2*Math.PI/5) - p.area;
		assertTrue(darea*darea < 1e-10);	
	}

}
