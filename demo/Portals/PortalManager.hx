package;

import nape.space.Space;
import nape.phys.Body;
import nape.phys.Interactor;
import nape.geom.Vec2;
import nape.shape.Shape;
import nape.dynamics.Arbiter;
import nape.dynamics.InteractionFilter;

import nape.callbacks.CbType;
import nape.callbacks.CbType;
import nape.callbacks.CbEvent;
import nape.callbacks.PreFlag;
import nape.callbacks.PreCallback;
import nape.callbacks.PreListener;
import nape.callbacks.InteractionCallback;
import nape.callbacks.InteractionListener;
import nape.callbacks.InteractionType;
import nape.callbacks.Listener;

import PortalConstraint;

/*
	Class to manage all portal behaviours.
*/

class PortalManager {
	/*
		CbTypes to be used by User to inject portal behaviour
		to objects.

		These CbTypes must only be used on SHAPES!!
	*/
	public static var Portal   = new CbType();
	public static var Portable = new CbType();

	///------------------------------------------------------------------------

	// internal type representing a Shape which is partially
	// passed through a Portal.
	public static var InOut = new CbType();

	//all active objects shit.
	private var infos  :Array<PortalInfo>;
	private var limbos :Array<Limbo>;

	//Remove element from list (swap-pop)
	private static inline function delfrom<T>(list:Array<T>,obj:T) {
		for(i in 0...list.length) {
			if(list[i]==obj) {
				list[i] = list[list.length-1];
				list.pop();
				break;
			}
		}
	}

	//retrieve PortalInfo for given (PortalData,Body) pair.
	private function getinfo(portal:PortalData, object:Body):PortalInfo {
		for(i in infos) {
			if((portal==i.mportal && object==i.master)
			|| (portal==i.sportal && object==i.slave))
				return i;
		}
		return null;
	}

	//retrive Limbo for given Shape in PortalInfo
	private function infolimbo(info:PortalInfo,shape:Shape):Limbo {
		if(info==null) return null;
		for(i in info.limbos) { if(i.mshape==shape || i.sshape==shape) return i; }
		return null;
	}

	//determine if shape is in any portal instance, in limbo
	private function inlimbo(shape:Shape, climbo:Limbo=null) {
		for(i in limbos) {
			if(i!=climbo && (i.sshape==shape || i.mshape==shape)) {
				var skip = false;
				for(h in histories) if(h.limbo==i) { skip = true; break; }
				if(skip) continue;
				return true;
			}
		}
		return false;
	}

	///------------------------------------------------------------------------

	//determine if position is behind portal.
	private function behind_portal(portal:PortalData, position:Vec2):Bool {
		var u = position.sub(portal.body.localToWorld(portal.position,true));
		var v = portal.body.localToRelative(portal.direction);
		var y = u.dot(v);
		u.dispose();
		v.dispose();
		return y<=0;
	}

	private function prevent_back_collisions(cb:PreCallback):PreFlag {
		var arb = cb.arbiter;
		var carb = arb.collisionArbiter;
		var ret = PreFlag.ACCEPT_ONCE;
		for(shape in [arb.shape1,arb.shape2]) {
			if(!shape.cbTypes.has(InOut)) continue;

			var i = 0;
			while(i<carb.contacts.length) {
				var c = carb.contacts.at(i);
				var rem = false;
				for(limbo in limbos) {
					if(limbo.mshape!=shape && limbo.sshape!=shape) continue;
					var info = limbo.info;
					var portal = if(shape.body==info.master) info.mportal else info.sportal;

					if(behind_portal(portal,c.position)) { rem = true; break; }
				}
				if(rem) {
					carb.contacts.remove(c);
					continue;
				}else i++;
			}
			if(carb.contacts.length==0) { ret = PreFlag.IGNORE_ONCE; break; }
		}
		return ret;
	}

	///------------------------------------------------------------------------

	private function ignore_portal_interaction(cb:PreCallback) return PreFlag.IGNORE

	///------------------------------------------------------------------------

	private function start_portal(cb:InteractionCallback) {
		var pshape = cb.int1.castShape;
		var object = cb.int2.castShape;
		var portal:PortalData = cast(pshape.userData,PortalData);

		var info = getinfo(portal,object.body);
		var limbo = infolimbo(info,object);

		//delete any relevant pending histories
		for(h in histories) {
			if((h.limbo.sshape == object || h.limbo.mshape == object)
			&& (h.info == info)) {
				delfrom(histories,h);
			}
		}

		//limbo already exists for this shape in portalinfo!
		//reference count++;
		if(limbo!=null) {
			limbo.cnt++;
			return;
		}

		var nortal = portal.target;
		var scale = nortal.width/portal.width;
		
		//new portal interaction!
		if(info==null) {
			var clone = new Body();
			var clone_shp = Shape.copy(object);
			clone_shp.scale(scale,scale);
			clone_shp.body = clone;
			clone.space = object.body.space;

			var pcon = new PortalConstraint(
				portal.body, portal.position, portal.direction,
				nortal.body, nortal.position, nortal.direction,
				scale, object.body, clone
			);
			pcon.space = object.body.space;
			pcon.setProperties(clone,object.body);

			info = new PortalInfo();
			info.master = object.body;
			info.slave = clone;
			info.mportal = portal;
			info.sportal = nortal;
			info.pcon = pcon;
			info.count = object.body.shapes.length;

			var nlimbo = new Limbo(); nlimbo.cnt = 1;
			nlimbo.mshape = object;
			nlimbo.sshape = clone_shp;
			info.limbos.push(nlimbo);
			nlimbo.info = info;
	
			infos.push(info);
			limbos.push(nlimbo);

			object.cbTypes.add(InOut);
			clone_shp.cbTypes.add(InOut);
		}
		//portal interaction exists already!
		//just need too add new limboed-shape
		else {
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

			object.cbTypes.add(InOut);
			clone_shp.cbTypes.add(InOut);
		}
	}

	///------------------------------------------------------------------------

	//used for another possible bug condition resulting from portals being chained together
	//so that one shape can exist in many places at a time.
	//we need to defer deletion of cloned bodies etc, so that we cannot get in a situation
	//where an ongoing chain is broken 'in the middle' causing it to bug out.
	//
	//to resolve this we defer any deletions of shapes that exist in other portal instances
	//until 'all' portal instances are resolved.
	private var histories:Array<{limbo:Limbo, info:PortalInfo, remove:Shape}>;

	private function end_portal(cb:InteractionCallback) {
		var pshape = cb.int1.castShape;
		var object = cb.int2.castShape;
		var portal:PortalData = cast(pshape.userData,PortalData);
		var info = getinfo(portal,object.body);
		var limbo = infolimbo(info,object);

		//shape may still be in limbo. we wait until shape and it's clone have both left.
		if((--limbo.cnt)!=0) return;

		//shape that should be removed from.
		var remove = if((object==limbo.mshape) != behind_portal(portal,object.worldCOM)) limbo.sshape else limbo.mshape;

		//if shape is still in limbo, apart from the current limbo object
		//we need to defer deletions.
		if(inlimbo(object, limbo)) {
			histories.push({limbo:limbo,info:info,remove:remove});
			return;
		}

		enact_history(limbo,info,remove);
	}

	private function enact_history(limbo:Limbo, info:PortalInfo, remove:Shape) {
		//enact any relevant histories.
		for(h in histories) {
			if((h.remove == limbo.sshape || h.remove==limbo.mshape)
			&& h.info == info) {
				delfrom(histories, h);
				enact_history(h.limbo, h.info, h.remove);
			}
		}

		remove.body = null;
		delfrom(info.limbos,limbo);
		delfrom(limbos,limbo);

		if(info.limbos.length!=0) return;

		//check if entire object has left both portals.
		if(info.master.shapes.length==0 || info.slave.shapes.length==0) {
			//delete info, resetting cbtypes and remove empty body.
			delfrom(infos,info);
			info.pcon.space = null;

			if(info.master.shapes.length==0) {
				info.master.space = null;
				for(s in info.slave.shapes) if(!inlimbo(s)) s.cbTypes.remove(InOut);
			}else {
				info.slave.space = null;
				for(s in info.master.shapes) if(!inlimbo(s)) s.cbTypes.remove(InOut);
			}
		}
		//detect a bug condition where compound object has been forced through portal in a strange way
		//so that no shapes are intersecting portals, but body has been disjointed!
		//resolve by forcing unification to one side.
		else if(info.master.shapes.length + info.slave.shapes.length == info.count) {
			var keep = if(info.master.shapes.length > info.slave.shapes.length) info.master else info.slave;
			var dest = if(keep==info.master) info.slave else info.master;
			var kportal = if(keep==info.master) info.mportal else info.sportal;
			var dportal = if(keep==info.master) info.sportal else info.mportal;

			//delete info, resetting cbtypes and remove body about to be made empty.
			delfrom(infos,info);
			info.pcon.space = null;
		
			dest.space = null;
			var scale = kportal.width/dportal.width;
			while(!dest.shapes.empty()) {
				var s = dest.shapes.pop();
				s.body = keep;
				s.scale(scale,scale);
			}
			for(s in keep.shapes) if(!inlimbo(s)) s.cbTypes.remove(InOut);
		}
	}

	///------------------------------------------------------------------------

	private var listeners:Array<Listener>;
	public function new(space:Space) {
		for(x in listeners = [
			new PreListener(InteractionType.COLLISION, InOut, CbType.ANY_SHAPE.exclude(Portal), prevent_back_collisions),
			new PreListener(InteractionType.ANY, CbType.ANY_SHAPE, Portal, ignore_portal_interaction),
			new InteractionListener(CbEvent.BEGIN, InteractionType.ANY, Portal, Portable, start_portal),
			new InteractionListener(CbEvent.END, InteractionType.ANY, Portal, InOut, end_portal)
		]) x.space = space;

		limbos = [];
		infos = [];
		histories = [];
	}

	public function dispose() {
		//do some cleanup of InOut shapes etc??
		for(x in listeners) x.space = null;
		listeners = null;
		limbos = null;
		infos = null;
	}
}

//-----------------------------------------------------------------------------

/*
	Record of each shape running through portal manager for each portal instance
	it is running through with the master/slave relationship.
*/
class Limbo {
	public var mshape:Shape; //master
	public var sshape:Shape; //slave

	//portal instance related to
	//and count representing how many of mshape/shape are still intersecting
	//the relevant portal sensor.
	public var info:PortalInfo;
	public var cnt:Int;

	public function new() {
		cnt = 0;
	}
}

/*
	Record of each body running through portal manager for each portal instance
	it is running through with master/slave relationship.
*/
class PortalInfo {
	//source body
	public var master:Body;
	public var mportal:PortalData;

	//destination body
	public var slave:Body;
	public var sportal:PortalData;

	//total shape count to detect bug condition
	public var count:Int;

	//related limbos
	public var limbos:Array<Limbo>;
	
	//constraint
	public var pcon:PortalConstraint;

	public function new() {
		limbos = [];
	}
}

