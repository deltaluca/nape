package;

import nape.space.Space;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.shape.Circle;
import nape.shape.Polygon;
import nape.geom.Vec2;
import nape.geom.Mat23;
import nape.util.BitmapDebug;
import nape.constraint.PivotJoint;
import nape.constraint.WeldJoint;
import nape.constraint.LineJoint;
import nape.constraint.DistanceJoint;
import nape.constraint.Constraint;

import FixedStep;

class ConstraintStressTest extends FixedStep {
	static function main() new ConstraintStressTest()
	function new() {
		super(1/60);

		var space = new Space(new Vec2(0,400));
		var debug = new BitmapDebug(800,600,0x333333);
        debug.drawConstraints = true;
        debug.drawConstraintSprings = true;
        debug.transform = new Mat23(0.5, 0, 0, 0.5);
		addChild(debug.display);

        function weak(c:Body->Body->Constraint) {
            return function (a:Body, b:Body):Constraint {
                var ret = c(a, b);
                ret.stiff = false;
                return ret;
            }
        }

        var cs:Array<Dynamic> = [
            8, function (a:Body, b:Body):Constraint return new LineJoint(a, b, new Vec2(0, 7.5), new Vec2(0, -7.5), new Vec2(1, 0), -5, 5),
            18, weak(function (a:Body, b:Body):Constraint return new LineJoint(a, b, new Vec2(0, 7.5), new Vec2(0, -7.5), new Vec2(1, 0), -5, 5)),
            80, function (a:Body, b:Body):Constraint return new PivotJoint(a, b, new Vec2(0, 7.5), new Vec2(0, -7.5)),
            25, weak(function (a:Body, b:Body):Constraint return new PivotJoint(a, b, new Vec2(0, 7.5), new Vec2(0, -7.5))),
            80, function (a:Body, b:Body):Constraint return new WeldJoint(a, b, new Vec2(0, 7.5), new Vec2(0, -7.5)),
            25, weak(function (a:Body, b:Body):Constraint return new WeldJoint(a, b, new Vec2(0, 7.5), new Vec2(0, -7.5))),
            90, function (a:Body, b:Body):Constraint return new DistanceJoint(a, b, new Vec2(0, 2.5), new Vec2(0, -2.5), 5, 10),
            30, weak(function (a:Body, b:Body):Constraint return new DistanceJoint(a, b, new Vec2(0, 2.5), new Vec2(0, -2.5), 5, 10)),
        ];

        for (k in 0...(cs.length>>1))
        {
            var bs = [];
            var num:Int = cs[k*2];
            for (i in 0...num)
            {
                var b = new Body();
                b.shapes.add(new Circle(5));
                b.position.setxy(20+k*20, 20 + i*15);
                b.shapes.at(0).material.density *= 1000;
                b.space = space;
                b.angularVel = 1;
                b.velocity.x = i;
                if (i == 0) {
                    b.allowMovement = false;
                }
                bs.push(b);
            }

            for (i in 0...num-1)
            {
                var c:Constraint = cs[k*2+1](bs[i], bs[i+1]);
                c.space = space;
            }
        }

		run(function (dt) {
			debug.clear();
			space.step(dt);
			debug.draw(space);
			debug.flush();
		});
	}
}

