package;

import nape.space.Space;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.shape.Polygon;
import nape.shape.Circle;
import nape.geom.Vec2;
import nape.util.BitmapDebug;
import nape.geom.Vec3;

import nape.constraint.UserConstraint;
import nape.constraint.PivotJoint;

import FixedStep;
import FPS;

#if flash9
	typedef ARRAY<T> = flash.Vector<T>;
#else
	typedef ARRAY<T> = Array<T>;
#end

class UserPivotJoint extends UserConstraint {
	public var body1(default,set_body1):Body;
	public var body2(default,set_body2):Body;

	public var anchor1:Vec2;
	public var anchor2:Vec2;

	//. this handles body assignment perfectly!
	//  registerBody will deregister the old one, and register the new one returning it
	//. registering/deregestering occur in pairs and can happen multiple times.
	//. null values are checked to make sure everything occurs as it should internally.
	function set_body1(b:Body) { return this.body1 = registerBody(this.body1,b); }
	function set_body2(b:Body) { return this.body2 = registerBody(this.body2,b); }

	public function new(body1:Body,body2:Body,anchor1:Vec2,anchor2:Vec2) {
		super(2); //2 dimensional constraint.

		this.body1 = body1;
		this.body2 = body2;

		this.anchor1 = anchor1;
		this.anchor2 = anchor2;
	}

	//------------------------------------------------------------

	public override function __copy():UserConstraint {
		//simply need to produce a copy of the constraint in this manner
		//when the normal Constraint::copy() function is called
		//this method is called first, and then all other properties shared between Constraints
		//are copied also.
		return new UserPivotJoint(body1,body2,anchor1,anchor2);
	}

	//public override function __destroy():Void {} //nothing extra needs to be done

	var rel1:Vec2;
	var rel2:Vec2;
	public override function __validate():Void {
		//here we can pre-calculate anything that is persistant throughout a step
		//in this case, the relative anchors for each body to be used
		//throughout the velocity iterations.
		rel1 = body1.localToRelative(anchor1);
		rel2 = body2.localToRelative(anchor2);
	}

	//--------------------------------------------------------------

	//positional error
	public override function __position(err:ARRAY<Float>) {
		err[0] = (body2.position.x + rel2.x) - (body1.position.x + rel1.x);
		err[1] = (body2.position.y + rel2.y) - (body1.position.y + rel1.y);
	}

	//velocity error (time-derivative of positional error)
	public override function __velocity(err:ARRAY<Float>) {
		var v1 = body1.constraintVelocity;
		var v2 = body2.constraintVelocity;
		err[0] = (v2.x - rel2.y*v2.z) - (v1.x - rel1.y*v1.z);
		err[1] = (v2.y + rel2.x*v2.z) - (v1.y + rel1.x*v1.z);
	}

	//effective mass matrix
	//K = J*M^-1*J^T where J is the jacobian of the velocity error.
	//
	//output should be a compact version of the eff-mass matrix like
	// [ eff[0], eff[1] ]
	// [ eff[1], eff[2] ]
	public override function __eff_mass(positional:Bool,eff:ARRAY<Float>) {
		//recompute relative vectors for positional updates
		if(positional) __validate();
		//constraintMass is well defined on all bodies as the mass/inertia we should use for constraints
		var im1 = body1.constraintMass; var ii1 = body1.constraintInertia;
		var im2 = body2.constraintMass; var ii2 = body2.constraintInertia;
		eff[0] = im1+im2 + rel1.y*rel1.y*ii1 + rel2.y*rel2.y*ii2;
		eff[1] =         - rel1.y*rel1.x*ii1 - rel2.y*rel2.x*ii2;
		eff[2] = im1+im2 + rel1.x*rel1.x*ii1 + rel2.x*rel2.x*ii2;
	}

	//public override function __clamp(jAcc:ARRAY<Float>):Void {} // nothing needs to be done here.

	//--------------------------------------------------------------

	//this is computed as a selection from the full world impulse
	//imp = J^T * constraint_imp
	public override function __impulse(imp:ARRAY<Float>,body:Body,out:Vec3) {
		var scale = if(body==body1) -1.0 else 1.0;
		var rel   = if(body==body1) rel1 else rel2;
		out.x = imp[0]*scale;
		out.y = imp[1]*scale;
		out.z = scale*rel.cross(Vec2.weak(imp[0],imp[1]));
	}

}

class UserDefinedConstraints extends FixedStep {
	static function main() {
		new UserDefinedConstraints();
	}
	function new() {
		super(1/60);

		var space = new Space(new Vec2(0,400));
		var debug = new BitmapDebug(stage.stageWidth,stage.stageHeight,0x333333);
//		debug.drawConstraints = true;
		addChild(debug.display);

		addChild(new FPS(stage.stageWidth,60,0,60,0x40000000,0xffffffff,0xa0ff0000));

		//borders
		var border = new Body(BodyType.STATIC);
		border.shapes.add(new Polygon(Polygon.rect(0,0,-40,stage.stageHeight)));
		border.shapes.add(new Polygon(Polygon.rect(stage.stageWidth,0,40,stage.stageHeight)));
		border.shapes.add(new Polygon(Polygon.rect(0,0,stage.stageWidth,-40)));
		border.shapes.add(new Polygon(Polygon.rect(0,stage.stageHeight,stage.stageWidth,40)));
		border.space = space;

		var b1 = new Body();
		b1.shapes.add(new Circle(50));
		b1.position.setxy(200,225);
		b1.space = space;

		var b2 = new Body();
		b2.shapes.add(new Circle(50));
		b2.position.setxy(400,225);
		b2.space = space;
		b2.velocity.y = -100;

		var piv = new PivotJoint(b1,b2,new Vec2(80,0), new Vec2(-80,0));
		piv.breakUnderError = true;
		piv.maxError = 100;
		piv.space = space;

		var hand = new PivotJoint(space.world,null,new Vec2(),new Vec2());
		hand.stiff = false;
		hand.active = false;
		hand.space = space;
		stage.addEventListener(flash.events.MouseEvent.MOUSE_DOWN, function (_) {
			var mp = new Vec2(mouseX,mouseY);
			for(b in space.bodiesUnderPoint(mp)) {
				if(b.isDynamic()) {
					hand.body2 = b;
					hand.anchor2 = b.worldToLocal(mp);
					hand.active = true;
				}
			}
		});
		stage.addEventListener(flash.events.MouseEvent.MOUSE_UP, function (_) {
			hand.active = false;
		});

		run(function (dt) {
			hand.anchor1.setxy(mouseX,mouseY);

			debug.clear();
			space.step(dt,1,1);
			debug.draw(space);
			debug.flush();
		});
	}
}
