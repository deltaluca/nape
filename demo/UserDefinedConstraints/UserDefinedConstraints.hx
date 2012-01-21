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

	//this handles body assignment perfectly!
	//register/unregister can be called multiple times with the same body
	//so this case is handled. They also allow null arguments
	//so that checking for null before calling is not needed.
	function set_body1(b:Body):Body {
		unregisterBody(this.body1);
		this.body1 = b;
		registerBody(this.body1);
		return this.body1;
	}	
	function set_body2(b:Body):Body {
		unregisterBody(this.body2);
		this.body2 = b;
		registerBody(this.body2);
		return this.body2;
	}	

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
	public override function __destroy():Void {
		//nothing extra needs to be done.
	}	

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

	inline function array(x) return #if flash9 flash.Vector.ofArray(x) #else x #end

	//positional error
	public override function __position():ARRAY<Float> {
		return array([
			(body2.position.x + rel2.x) - (body1.position.x + rel1.x),
			(body2.position.y + rel2.y) - (body1.position.y + rel1.y)
		]);
	}

	//velocity error (time-derivative of positional error)
	public override function __velocity():ARRAY<Float> {

		var v1 = body1.velocity.add(body1.kinematicVel); var w1 = body1.angularVel + body1.kinAngVel;
		var v2 = body2.velocity.add(body2.kinematicVel); var w2 = body2.angularVel + body2.kinAngVel;
		return array([
			(v2.x - rel2.y*w2) - (v1.x - rel1.y*w1),
			(v2.y + rel2.x*w2) - (v1.y + rel1.x*w1)
		]);
	}

	//effective mass matrix
	//K = J*M^-1*J^T where J is the jacobian of the velocity error.
	//
	//output should be a compact version of the eff-mass matrix like
	// [ ret[0], ret[1] ]
	// [ ret[1], ret[2] ]
	public override function __eff_mass(positional:Bool):ARRAY<Float> {
		//recompute relative vectors for positional updates
		if(positional) __validate();
		//non-dynamics are treat as having infinite mass.
		//so inverse mass is 0.
		var im1 = if(!body1.isDynamic()) 0.0 else 1.0/body1.mass;
		var im2 = if(!body2.isDynamic()) 0.0 else 1.0/body2.mass;
		var ii1 = if(!body1.isDynamic()) 0.0 else 1.0/body1.inertia;
		var ii2 = if(!body2.isDynamic()) 0.0 else 1.0/body2.inertia;
		return array([
			im1+im2 + rel1.y*rel1.y*ii1 + rel2.y*rel2.y*ii2,  -rel1.y*rel1.x*ii1 - rel2.y*rel2.x*ii2,
			                                         im1+im2 + rel1.x*rel1.x*ii1 + rel2.x*rel2.x*ii2
		]);
	}

	//public override function __clamp(jAcc:ARRAY<Float>):Void {} // nothing needs to be done here.

	//--------------------------------------------------------------

	//this is computed as a selection from the full world impulse
	//imp = J^T * constraint_imp
	public override function __impulse(imp:ARRAY<Float>,body:Body):Vec3 {
		var scale = if(body==body1) -1.0 else 1.0;
		var rel   = if(body==body1) rel1 else rel2;
		return new Vec3(
			scale*imp[0],
			scale*imp[1],
			scale*rel.cross(Vec2.weak(imp[0],imp[1]))
		);
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

		var piv = new UserPivotJoint(b1,b2,new Vec2(80,0), new Vec2(-80,0));
		piv.stiff = false;
		piv.space = space;

		run(function (dt) {
			debug.clear();
			space.step(dt,1,1);
			debug.draw(space);
			debug.flush();
		});
	}
}
