package {
	//partial implementation of haXe demo to demonstrate building the constraint in AS3.
	//see haXe version for descriptive comments!

	import nape.constraint.*;
	import nape.geom.*;
	import nape.util.*;
	import nape.phys.*;

	class UserWeldJoint extends UserConstraint {
		var _body1:Body;
		public function get body1():Body { return this._body1; }
		public function set body1(body1:Body):void { this._body1 = registerBody(this._body1,body1); }
		var _body2:Body;
		public function get body2():Body { return this._body2; }
		public function set body2(body2:Body):void { this._body2 = registerBody(this._body2,body2); }

		var _anchor1:Vec2;
		public function get anchor1():Vec2 { return this._anchor1; }
		public function set anchor1(anchor1:Vec2):void { this._anchor1.set(anchor1); }
		var _anchor2:Vec2;
		public function get anchor2():Vec2 { return this._anchor2; }
		public function set anchor2(anchor2:Vec2):void { this._anchor2.set(anchor2); }

		var _phase:Float;
		public function get phase():Number { return this._phase; }
		public function set phase(phase:Number):void {
			if(this.phase!=phase) invalidate();
			this._phase = phase;
		}
		
		public function UserWeldJoint(body1:Body,body2:Body,anchor1:Vec2,anchor2:Vec2,phase:Number=0.0):void {
			super(3);
			this.body1 = body1;
			this.body2 = body2;
			_anchor1 = bindVec2(); this.anchor1 = anchor1;
			_anchor2 = bindVec2(); this.anchor2 = anchor2;
			this.phase = phase;
		}	

		//rest is basicly exactly same as haXe version.
	}
}
