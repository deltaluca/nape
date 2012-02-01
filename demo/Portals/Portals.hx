package;

import nape.space.Space;
import nape.util.BitmapDebug;
import nape.phys.Body;
import nape.shape.Circle;
import nape.shape.Polygon;
import nape.shape.Shape;
import nape.callbacks.CbType;
import nape.callbacks.CbEvent;
import nape.callbacks.PreFlag;
import nape.callbacks.InteractionType;
import nape.callbacks.PreListener;
import nape.callbacks.InteractionListener;
import nape.dynamics.InteractionFilter;
import nape.geom.Vec2;
import nape.constraint.PivotJoint;
import nape.phys.Material;
import nape.phys.BodyType;
import nape.phys.Interactor;
import nape.dynamics.Arbiter;

import FixedStep;
import FPS;
import PortalConstraint;

class Limbo {
	public var mshape:Shape; //master
	public var sshape:Shape; //slave

	public var info:PortalInfo;
	public var cnt:Int;
	
	public function new() {
		cnt = 0;
	}
}

class PortalInfo {
	//source body
	public var master:Body;
	public var mportal:Portal;

	//destination body
	public var slave :Body;
	public var sportal:Portal;

	//all shapes in limbo intersecting exit shape
	public var limbos:Array<Limbo>;

	public var pcon:PortalConstraint;

	public function new() {
		limbos = new Array<Limbo>();
	}
}

class Portal {
	//bound body
	public var body:Body;
	//portal shape (belonging to body)
	public var sensor:Shape;

	//local coordiantes
	public var position :Vec2;
	public var direction:Vec2;

	//linked portal
	public var target:Portal;
	public var width:Float;

	public function new(body:Body, sensor:Shape, position:Vec2, direction:Vec2, width:Float) {
		this.body = body;
		this.sensor = sensor;
		this.position = position;
		this.direction = direction;
		this.width = width;

		sensor.cbType = PortalManager.PORTAL;
		sensor.filter = new InteractionFilter(-1,-1,-1,-1,-1,-1);
		sensor.userData = this;

		for(s in body.shapes) {
			if(s==sensor || s.cbType==PortalManager.PORTAL) continue;
			s.cbType = PortalManager.OBJECT;
		}
	}
}

class PortalManager {
	//portal sensors.
	public static var PORTAL = new CbType();
	public static var OBJECT = new CbType();

	public static var PORTER = new CbType(); //object that can be teleported.
	public static var INOUT  = new CbType(); //object which is part of an on-going portal interaction (in limbo)

	public var portals:Array<Portal>;
	public var infos  :Array<PortalInfo>;
	public var limbos :Array<Limbo>;

	public function new() {
		portals = new Array<Portal>();
		infos   = new Array<PortalInfo>();
		limbos  = new Array<Limbo>();
	}

	static function delfrom<T>(list:Array<T>,obj:T) {
		for(i in 0...list.length) {
			if(list[i]==obj) {
				list[i] = list[list.length-1];
				list.pop();
				break;
			}
		}
	}

	public function init(space:Space) {
		//ignore relevant contacts for shapes in limbo
		for(cb in [OBJECT,INOUT,PORTER]) {
			space.listeners.add(new PreListener(InteractionType.COLLISION, cb, INOUT, function(arb:Arbiter) {
				var carb = arb.collisionArbiter;
				function eval(ret:PreFlag, shape:Shape) {
					if(ret==PreFlag.IGNORE_ONCE) return ret;
					var i = 0;
					while(i<carb.contacts.length) {
						var c = carb.contacts.at(i);
						var rem = false;
						for(limbo in limbos) {
							if(limbo.mshape!=shape && limbo.sshape!=shape) continue;
							var info = limbo.info;
							var portal = if(shape.body==info.master) info.mportal else info.sportal;
							var del = c.position.sub(portal.body.localToWorld(portal.position)).dot(portal.body.localToRelative(portal.direction));
							if(del<=0) { rem = true; break; }
						}
						if(rem) {
							carb.contacts.remove(c);
							break;
						}else i++;
					}
					if(carb.contacts.length==0) return PreFlag.IGNORE_ONCE;
					else return ret;
				}
				var ret = PreFlag.ACCEPT_ONCE;
				if(arb.shape1.cbType==INOUT) ret = eval(ret, arb.shape1);
				if(arb.shape2.cbType==INOUT) ret = eval(ret, arb.shape2);
				return ret;
			}));
		}

		//ignore portal interactions
		for(cb in [PORTER,INOUT])
			space.listeners.add(new PreListener(InteractionType.ANY, cb, PORTAL, function(_) return PreFlag.IGNORE));

		function getinfo(portal:Portal, object:Body):PortalInfo {
			for(i in infos) {
				if((portal==i.mportal && object==i.master)
				|| (portal==i.sportal && object==i.slave))
					return i;
			}
			return null;
		}
		function infolimbo(info:PortalInfo,shape:Shape) {
			if(info==null) return null;
			for(i in info.limbos) if(i.mshape==shape || i.sshape==shape) return i;
			return null;
		}

		space.listeners.add(new InteractionListener(CbEvent.END, InteractionType.ANY, PORTAL, INOUT,
		function (_pshape:Interactor,_object:Interactor, _) {
			var pshape = _pshape.castShape;
			var object = _object.castShape;
			var portal:Portal = cast pshape.userData;	
			var info = getinfo(portal,object.body);
			var limbo = infolimbo(info,object);
			if((--limbo.cnt)!=0) return;

			var del = object.worldCOM.sub(portal.body.localToWorld(portal.position)).dot(portal.body.localToRelative(portal.direction));
			if(del<=0) {//reimove object from it's body
				object.body = null;
			}else {
				if(object==limbo.mshape) limbo.sshape.body = null;
				else limbo.mshape.body = null;
			}
			delfrom(info.limbos,limbo);	
			delfrom(limbos,limbo);

			if(info.master.shapes.length==0 || info.slave.shapes.length==0) {
				//delete info
				info.pcon.space = null;
				if(info.master.shapes.length==0) info.master.space = null;
				else                             info.slave.space = null;
				delfrom(infos,info);
			}
		}));

		for(cb in [PORTER,INOUT]) {
			space.listeners.add(new InteractionListener(CbEvent.BEGIN, InteractionType.ANY, PORTAL, cb,	
			function (_pshape:Interactor,_object:Interactor, _) {
				var pshape = _pshape.castShape; 
				var object = _object.castShape;
				var portal:Portal = cast pshape.userData;

				var info = getinfo(portal,object.body);
				var limbo = infolimbo(info,object);
				if(limbo!=null) {
					limbo.cnt++;
					return;
				}

				var nortal = portal.target;
				var scale = nortal.width/portal.width;
				if(info==null) {
					var clone = new Body();
					var clone_shp = Shape.copy(object);
					clone_shp.scale(scale,scale);
					clone_shp.body = clone;
					clone.space = space;

					var pcon = new PortalConstraint(
						portal.body, portal.position, portal.direction,
						nortal.body, nortal.position, nortal.direction,
						scale,
						object.body,clone
					);
					pcon.space = space;
					pcon.set_properties(clone,object.body);

					info = new PortalInfo();
					info.master = object.body;
					info.mportal = portal;
					info.slave = clone;
					info.sportal = nortal;
					info.pcon = pcon;
					
					var nlimbo = new Limbo(); nlimbo.cnt = 1;
					nlimbo.mshape = object;
					nlimbo.sshape = clone_shp;
					
					info.limbos.push(nlimbo);
					nlimbo.info = info;

					infos.push(info);
					limbos.push(nlimbo);

					object.cbType = INOUT;
					clone_shp.cbType = INOUT;
				}else {
					var clone = if(info.master==object.body) info.slave else info.master;
					var clone_shp = Shape.copy(object);
					clone_shp.scale(scale,scale);
					clone_shp.body = clone;
					
					var nlimbo = new Limbo(); nlimbo.cnt = 1;
					nlimbo.mshape = if(info.master==object.body) clone_shp else object;
					nlimbo.sshape = if(info.master==object.body) object else clone_shp;

					info.limbos.push(nlimbo);
					nlimbo.info = info;

					limbos.push(nlimbo);
					
					object.cbType = INOUT;
					clone_shp.cbType = INOUT;
				}
			}));
		}
	}
}

class Portals extends FixedStep {
	static function main() {
		new Portals();
	}
	function new() {	
		super(1/60);

		var space = new Space();
		var debug = new BitmapDebug(stage.stageWidth,stage.stageHeight,0x333333);
		debug.drawConstraints = true;
		addChild(debug.display);
		addChild(new FPS(stage.stageWidth,60,0,60,0x40000000,0xffffffff,0xa0ff0000));

		var border = new Body(BodyType.STATIC);
		border.shapes.add(new Polygon(Polygon.rect(0,0,-50,stage.stageHeight)));
		border.shapes.add(new Polygon(Polygon.rect(stage.stageWidth,0,50,stage.stageHeight)));
		border.shapes.add(new Polygon(Polygon.rect(0,0,stage.stageWidth,-50)));
		border.shapes.add(new Polygon(Polygon.rect(0,stage.stageHeight,stage.stageWidth,50)));
		border.space = space;
		for(s in border.shapes) s.cbType = PortalManager.OBJECT;

		//-------------------------------------------------------------------------

		for(p in [
			new Vec2(200,225),new Vec2(400,225),new Vec2(300,125),new Vec2(300,325),
			new Vec2(50,50),new Vec2(550,50),new Vec2(50,400),new Vec2(550,400)
		]) {
			var b = new Body();
			b.position = p;
			b.shapes.add(new Circle(12,new Vec2(12*0.86,-6)));
			b.shapes.add(new Circle(12,new Vec2(0,12)));
			b.shapes.add(new Circle(12,new Vec2(-12*0.86,-6)));
			b.space = space;
			for(s in b.shapes) s.cbType = PortalManager.PORTER;
		}

		//-------------------------------------------------------------------------

		function genportal(pos:Vec2,dir:Vec2,w:Float) {
			var b = new Body(BodyType.STATIC);
			b.position.set(pos);
			b.rotation = dir.angle;

			var d = 8;
			var port = new Polygon(Polygon.box(d,w));
			port.body = b;

			b.shapes.add(new Polygon(Polygon.rect(-d/2,-w/2,d,-d)));
			b.shapes.add(new Polygon(Polygon.rect(-d/2, w/2,d, d)));
			b.shapes.add(new Polygon(Polygon.rect(-d/2,-w/2-d,-d,w+d*2)));
			b.align();

			b.space = space;

			var p = new Portal(b,port,port.localCOM.add(new Vec2(d/2.1,0)),new Vec2(1,0),w);
			return p;
		}

		var p1 = genportal(new Vec2(100,225),new Vec2(1,0),150);
		var p2 = genportal(new Vec2(500,225),new Vec2(-1,0),100);
		var p3 = genportal(new Vec2(300,25),new Vec2(0,1),150);
		var p4 = genportal(new Vec2(300,425),new Vec2(0,-1),100);

		p1.target = p2;
		p2.target = p3;
		p3.target = p4;
		p4.target = p1;

		p1.body.type = BodyType.KINEMATIC;
		p2.body.type = BodyType.KINEMATIC;
		p2.body.angularVel = 1;

		//funky portal body now :)
		var b = new Body(BodyType.DYNAMIC,new Vec2(300,225));
		b.shapes.add(new Polygon(Polygon.box(84,100)));
		b.shapes.add(new Polygon(Polygon.rect(-42,-42,-8,-8)));
		b.shapes.add(new Polygon(Polygon.rect(-42,42,-8,8)));
		b.shapes.add(new Polygon(Polygon.rect(42,-42,8,-8)));
		b.shapes.add(new Polygon(Polygon.rect(42,42,8,8)));
		for(s in b.shapes) s.cbType = PortalManager.OBJECT;

		var port1 = new Polygon(Polygon.rect(-42,-42,-8,84));
		var port2 = new Polygon(Polygon.rect(42,-42,8,84));
		port1.body = b;
		port2.body = b;

		b.space = space;
		b.rotation = Math.PI/4;

		var q1 = new Portal(b,port1,port1.localCOM.add(new Vec2(-8/2.1,0)),new Vec2(-1,0),84);
		var q2 = new Portal(b,port2,port2.localCOM.add(new Vec2( 8/2.1,0)),new Vec2(1,0),84);
		q1.target = q2;
		q2.target = q1;

		//-------------------------------------------------------------------------

		var hand = new PivotJoint(space.world,null,new Vec2(),new Vec2());
		hand.active = false;
		hand.stiff = false;
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

		//-------------------------------------------------------------------------

		var manager = new PortalManager();
		manager.init(space);

		run(function (dt) {
			for(p in space.liveBodies) {
				p.velocity.muleq(0.99); p.angularVel *= 0.99;
			}

			p1.body.velocity.y = Math.cos(space.elapsedTime)*50;

			if(hand.active && hand.body2.space==null) { hand.body2 = null; hand.active = false; }
			hand.anchor1.setxy(mouseX,mouseY);

			debug.clear();
			space.step(dt);
			debug.draw(space);
			debug.flush();
		});	
	}
}
