package;

import nape.constraint.UserConstraint;
import nape.phys.Body;
import nape.geom.Vec2;
import nape.geom.Vec3;
import nape.util.Debug;

typedef ARRAY<T> = #if flash9 flash.Vector<T> #else Array<T> #end;

/*
	Constraint for use in portal physics.

	A body and it's clone are linked via this constraint to act as a single
	entitity

	The portals are defined relative to two further bodies which are not
	themselves effect by the constraint. These bodies must be part of
	the constraint so that changes to them may 'wake' the constraint.

	The constraint is kind of like a crazy weldJoint of sorts :P

	Constraint is written to use object pools in all places to avoid
	thrashing GC with Vec2 invocations, but without resorting to hand
	writing all vector operations as speed is not critical here.
*/

/*
	Bodies b1,b2 and Portal bodies pb1,pb2
	Portal local positions lp1,lp2 and directions ld1,ld2
	Portal scaling λ

	To enact that portal bodies are not effected by constraint
	We give them implicit infinite mass.

	Velocity independent values:
		pi = pbi.localToRelative(lpi)
		ni = pbi.localToRelative(ldi)
		si = bi.position - pi - pbi.position
		ai = ldi.angle + pbi.rotation

	Velocity dependent values:
		ui = bi.velocity - pbi.angvel×pi - pbi.velocity

	Positional constraint:
		[              λ·s1·n1 + s2·n2            ]
		[              λ·s1×n1 + s2×n2            ]
		[ (b1.rotation-a1) - (b2.rotation-a2) - π ]

	Velocity constraint:
		[ λ·(u1·n1 + pb1.angvel·s1×n1) + (u2·n2 + pb2.angvel·s2×n2) ]
		[ λ·(u1×n1 + pb1.angvel·s1·n1) + (u2×n2 + pb2.angvel·s2·n2) ]
		[    (b1.angvel - pb1.angvel) - (b2.angvel - pb2.angvel)    ]

	Jacobian (assuming b1,b2,pb1,pb2 ordering):
		[ [ λn1.x  λn1.y 0 ]  [ n2.x  n2.y 0 ]       ]  # doesn't matter
		[ [ λn1.y -λn1.x 0 ], [ n2.y -n2.x 0 ], #, # ]    since we give
		[ [   0      0   1 ]  [  0     0  -1 ]       ]    infinite mass

	Eff-Mass matrix:
	[ λ²/b1.mass + 1/b2.mass          0                        0              ]
	[           0           λ²/b1.mass + 1/b2.mass             0              ]
	[           0                     0           1/b1.inertia + 1/b2.inertia ]

*/

class PortalConstraint extends UserConstraint {

	public var body1(default,set_body1):Body;
	public var body2(default,set_body2):Body;
	public var portalBody1(default,set_portalBody1):Body;
	public var portalBody2(default,set_portalBody2):Body;

	/*
		Portal positions+directions defined locally to each portalBody
	*/
	public var position1 (default,set_position1 ):Vec2;
	public var position2 (default,set_position2 ):Vec2;
	public var direction1(default,set_direction1):Vec2;
	public var direction2(default,set_direction2):Vec2;

	/*
		Portal scaling from portal1 to portal2
	*/
	public var scale(default,set_scale):Float;

	//---------------------------------------------------------------------------

	function set_body1(body1:Body)
		return this.body1 = __registerBody(this.body1,body1)
	function set_body2(body2:Body)
		return this.body2 = __registerBody(this.body2,body2)

	function set_portalBody1(portalBody1:Body)
		return this.portalBody1 = __registerBody(this.portalBody1,portalBody1)
	function set_portalBody2(portalBody2:Body)
		return this.portalBody2 = __registerBody(this.portalBody2,portalBody2)

	function set_position1(position1:Vec2) {
		if(this.position1==null) this.position1 = __bindVec2();
		return this.position1.set(position1);
	}
	function set_position2(position2:Vec2) {
		if(this.position2==null) this.position2 = __bindVec2();
		return this.position2.set(position2);
	}

	function set_direction1(direction1:Vec2) {
		if(this.direction1==null) this.direction1 = __bindVec2();
		return this.direction1.set(direction1);
	}
	function set_direction2(direction2:Vec2) {
		if(this.direction2==null) this.direction2 = __bindVec2();
		return this.direction2.set(direction2);
	}

	function set_scale(scale:Float) {
		if(this.scale!=scale) __invalidate();
		return this.scale = scale;
	}

	//---------------------------------------------------------------------------

	public function new(portalBody1:Body,position1:Vec2,direction1:Vec2,
	                    portalBody2:Body,position2:Vec2,direction2:Vec2,
	                    scale:Float, body1:Body, body2:Body)
	{
		super(3); //3 dimensional constraint

		this.portalBody1 = portalBody1; this.portalBody2 = portalBody2;
		this.position1   = position1;   this.position2   = position2;
		this.direction1  = direction1;  this.direction2  = direction2;
		this.scale = scale;
		this.body1 = body1;
		this.body2 = body2;

		//init Vec2's that are reused across methods
		unit_dir1 = Vec2.get();
		unit_dir2 = Vec2.get();

		p1 = Vec2.get(); p2 = Vec2.get();
		s1 = Vec2.get(); s2 = Vec2.get();
		n1 = Vec2.get(); n2 = Vec2.get();
	}

	public override function __copy():UserConstraint {
		return new PortalConstraint(portalBody1,position1,direction1,
		                            portalBody2,position2,direction2,
		                            scale, body1, body2);
	}

	//---------------------------------------------------------------------------

	/*
		Method to be used in setting properties of a new clone so that the
		PortalConstraint will be in an already solved state, aka. set up clone to
		be perfectly in place already!
	*/
	public function setProperties(clone:Body,original:Body):Void {
		//ensure our required pre-calced values are correct.
		__validate();
		__prepare();
		//compute velocity error so we can set velocity correctly.
		var v = new ARRAY<Float>();
		__velocity(v);

		//modify clone so that position and velocity errors are 0
		if(clone==body2) {
			clone.position = portalBody2.position.add(p2,true);
			clone.position.x -= (n2.x * s1.dot(n1) + n2.y * s1.cross(n1))*scale;
			clone.position.y -= (n2.y * s1.dot(n1) - n2.x * s1.cross(n1))*scale;
			clone.rotation = -Math.PI + original.rotation - a1 + a2;

			clone.velocity.x -= n2.x * v[0] + n2.y * v[1];
			clone.velocity.y -= n2.y * v[0] - n2.x * v[1];
			clone.angularVel += v[2];
		}else {
			clone.position = portalBody1.position.add(p1, true);
			clone.position.x -= (n1.x * s2.dot(n2) + n1.y * s2.cross(n2))/scale;
			clone.position.y -= (n1.y * s2.dot(n2) - n1.x * s2.cross(n2))/scale;
			clone.rotation = Math.PI + original.rotation - a2 + a1;

			clone.velocity.x += (n1.x * v[0] + n1.y * v[1]) / scale;
			clone.velocity.y += (n1.y * v[0] - n1.x * v[1]) / scale;
			clone.angularVel += v[2];
		}
	}

	//---------------------------------------------------------------------------

	var unit_dir1:Vec2; var unit_dir2:Vec2;
	public override function __validate() {
		unit_dir1.set(direction1.mul(1/direction1.length, true));
		unit_dir2.set(direction2.mul(1/direction2.length, true));
	}

	var p1:Vec2;  var p2:Vec2;
	var s1:Vec2;  var s2:Vec2;
	var n1:Vec2;  var n2:Vec2;
	var a1:Float; var a2:Float;
	public override function __prepare() {
		p1.set(portalBody1.localToRelative(position1,true));
		p2.set(portalBody2.localToRelative(position2,true));

		s1.set(body1.position.sub(p1,true).subeq(portalBody1.position));
		s2.set(body2.position.sub(p2,true).subeq(portalBody2.position));

		n1.set(portalBody1.localToRelative(unit_dir1,true));
		n2.set(portalBody2.localToRelative(unit_dir2,true));

		a1 = unit_dir1.angle + portalBody1.rotation;
		a2 = unit_dir2.angle + portalBody2.rotation;
	}

	public override function __position(err:ARRAY<Float>) {
		err[0] = scale*s1.dot  (n1) + s2.dot  (n2);
		err[1] = scale*s1.cross(n1) + s2.cross(n2);
		err[2] = (body1.rotation - a1) - (body2.rotation - a2) - Math.PI;
	}

	public override function __velocity(err:ARRAY<Float>) {
		var v1 = body1.constraintVelocity;
		var v2 = body2.constraintVelocity;
		var pv1 = portalBody1.constraintVelocity;
		var pv2 = portalBody2.constraintVelocity;

		var u1 = v1.xy().subeq(p1.perp(true).muleq(pv1.z)).subeq(pv1.xy(true));
		var u2 = v2.xy().subeq(p2.perp(true).muleq(pv2.z)).subeq(pv2.xy(true));

		err[0] = scale*(u1.dot  (n1) + pv1.z*s1.cross(n1))
		             + (u2.dot  (n2) + pv2.z*s2.cross(n2));
		err[1] = scale*(u1.cross(n1) + pv1.z*s1.dot  (n1))
		             + (u2.cross(n2) + pv2.z*s2.dot  (n2));
		err[2] = (v1.z - pv1.z) - (v2.z - pv2.z);

		u1.dispose();
		u2.dispose();
	}

	public override function __eff_mass(eff:ARRAY<Float>) {
		eff[0]=eff[3]=body1.constraintMass*scale*scale + body2.constraintMass;
		eff[1]=eff[2]=eff[4] = 0.0;
		eff[5]= body1.constraintInertia + body2.constraintInertia;
	}

	public override function __impulse(imp:ARRAY<Float>,body:Body,out:Vec3) {
		if(body==portalBody1 || body==portalBody2) out.setxyz(0,0,0);
		else {
			var sc1, sc2, norm;
			if(body==body1) { sc1 = scale; sc2 =  1.0; norm = n1; }
			else            { sc1 = 1.0;   sc2 = -1.0; norm = n2; }
			out.x = sc1*(norm.x*imp[0] + norm.y*imp[1]);
			out.y = sc1*(norm.y*imp[0] - norm.x*imp[1]);
			out.z = sc2*imp[2];
		}
	}

	//---------------------------------------------------------------------------

	public override function __draw(debug:Debug) {
		__validate();
		var p1 = portalBody1.localToWorld(position1);
		var p2 = portalBody2.localToWorld(position2);

		debug.drawCircle(p1,2,0xff);
		debug.drawCircle(p2,2,0xff0000);
		debug.drawLine(p1,p1.add(portalBody1.localToRelative(unit_dir1,true).muleq(20),true),0xff);
		debug.drawLine(p2,p2.add(portalBody2.localToRelative(unit_dir2,true).muleq(20),true),0xff0000);
		debug.drawLine(p1,body1.position,0xffff);
		debug.drawLine(p2,body2.position,0xff00ff);

		p1.dispose();
		p2.dispose();
	}
}
