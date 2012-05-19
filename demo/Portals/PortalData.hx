package;

import nape.phys.Body;
import nape.shape.Shape;
import nape.geom.Vec2;
import nape.dynamics.InteractionFilter;

import PortalManager;

/*
	Object to be stored in any Shape having the Portal CbType's userData field
	required by PortalManager.
*/
class PortalData {
	//bound body
	public var body:Body;
	//portal shape (belonging to body)
	public var sensor:Shape;

	//local coordinates of portal and 'width'
	public var position :Vec2;
	public var direction:Vec2;
	public var width:Float;

	//linked portal
	public var target:PortalData;

	public function new(portal:Shape, position:Vec2, direction:Vec2, width:Float) {
		body = portal.body;
		sensor = portal;
		this.position = position;
		this.direction = direction;
		this.width = width;

		portal.cbTypes.add(PortalManager.Portal);
		portal.filter = new InteractionFilter(-1,-1,-1,-1,-1,-1);
		portal.userData = this;
	}
}
