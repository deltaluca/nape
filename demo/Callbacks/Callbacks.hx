package;

import FixedStep;

import nape.space.Space;
import nape.util.BitmapDebug;

import nape.phys.Body;
import nape.phys.BodyType;
import nape.phys.FluidProperties;
import nape.phys.Interactor;

import nape.shape.Circle;
import nape.shape.Polygon;

import nape.dynamics.Arbiter;
import nape.geom.Vec2;

import nape.callbacks.InteractionListener;
import nape.callbacks.PreListener;
import nape.callbacks.BodyListener;
import nape.callbacks.PreFlag;
import nape.callbacks.CbType;
import nape.callbacks.CbEvent;

import nape.constraint.PivotJoint;

class Callbacks extends FixedStep {
	static function main() {
		new Callbacks();
	}

	public function new() {
		super(1/60);

		var space = new Space(new Vec2(0,400));
		var debug = new BitmapDebug(stage.stageWidth,stage.stageHeight,0x333333,false);
		debug.drawCollisionArbiters = true;
		addChild(debug.display);

		var hand = new PivotJoint(space.world,space.world,new Vec2(),new Vec2());
		hand.stiff = false;
		hand.space = space;
		hand.active = false;

		addEventListener(flash.events.MouseEvent.MOUSE_DOWN, function(_) {
			var mp = new Vec2(mouseX,mouseY);
			for(b in space.bodiesUnderPoint(mp)) {
				if(!b.isDynamic()) continue;
				hand.body2 = b;
				hand.anchor2 = b.worldToLocal(mp);
				hand.active = true;
			}
		});
		addEventListener(flash.events.MouseEvent.MOUSE_UP, function(_) {
			hand.active = false;
		});

		//--------------------

		var border = new Body(BodyType.STATIC);
		border.shapes.add(new Polygon(Polygon.rect(0,0,-50,600)));
		border.shapes.add(new Polygon(Polygon.rect(800,0,50,600)));
		border.shapes.add(new Polygon(Polygon.rect(0,0,800,-50)));
		border.shapes.add(new Polygon(Polygon.rect(0,600,800,50)));
		border.space = space;

		//--------------------

		//partially penetratable Hexagons :)
		var hexcb = new CbType();

		for(i in 0...10) {
			var hex = new Body();
			hex.shapes.add(new Polygon(Polygon.regular(80,80,5)));
			hex.position.setxy(800/11*(i+1),150);
			hex.space = space;
			
			//set it's cbType
			hex.cbType = hexcb;
		}

		//aaand set up the pre-listener to do the partial penetration magic fun times.
		// note: this is a pure function with respect to the two objects
		//       (it's output doesn't change) so we can tell nape this and allow objects
		//       to sleep as normal.
		space.listeners.add(new PreListener(hexcb,hexcb,function(arb:Arbiter) {
			var depth = 15;

			if(arb.isCollisionArbiter()) {
				//to allow penetration, we need to both change contact penetrations,
				//and arbiter radius by same amount.
				var carb = arb.collisionArbiter;
				var i = 0; while(i<carb.contacts.length) {
					var con = carb.contacts.at(i);
					if(con.penetration <= depth) {
						carb.contacts.remove(con);
						continue;
					}else
						con.penetration -= depth;
					i++;
				}
				carb.radius -= depth;

				//no contacts left? ignore arbiter for now.
				//eitherway we use the *_ONCE flag as we need to continously perform these
				//modifications and checks.
				return if(carb.contacts.length==0) PreFlag.IGNORE_ONCE;
				       else PreFlag.ACCEPT_ONCE;

			}else
				return PreFlag.ACCEPT;
		},
		true //pure
		));

		//----------------------------

		//squares that report on BEGIN/END events.
		var boxcb = new CbType();

		for(i in 0...10) {
			var box = new Body();
			box.shapes.add(new Polygon(Polygon.box(40,40)));
			box.position.setxy(800/11*(i+1),100);
			box.space = space;
			
			//set it's cbType
			box.cbType = boxcb;
		}

		//setup listeners
		function boxer(colour:Int) { 
			return function(box1:Interactor,box2:Interactor) {
				//we gave the box bodies the cbType, rather than the shapes so we 'know'
				//we need to use interactor.body and not interator.shape
			
				//draw thick line using a quad.
				var p1 = cast(box1,Body).position;
				var p2 = cast(box2,Body).position;
				var n = p1.sub(p2);
				n.length=1; n.angle += Math.PI/2;
	
				debug.drawFilledPolygon([p1.sub(n),p2.sub(n),p2.add(n),p1.add(n)],colour);
			};
		}

		space.listeners.add(new InteractionListener(CbEvent.BEGIN, boxcb,boxcb, boxer(0x00ff00)));
		space.listeners.add(new InteractionListener(CbEvent.END,   boxcb,boxcb, boxer(0xff0000)));

		//----------------------------

		//flashing circles (on sleep/wake)
		var circcb = new CbType();

		for(i in 0...10) {
			var circ = new Body();
			circ.shapes.add(new Circle(15));
			circ.position.setxy(800/11*(i+1),50);
			circ.space = space;
			
			//set it's cbType
			circ.cbType = circcb;
		}

		//and set up listeners
		function circler(colour:Int) {
			return function(circle:Body) {
				debug.drawFilledCircle(circle.position,circle.shapes.at(0).circle.radius,colour);
			}
		}

		space.listeners.add(new BodyListener(CbEvent.WAKE,  circcb, circler(0x00ff00)));
		space.listeners.add(new BodyListener(CbEvent.SLEEP, circcb, circler(0xff0000)));

		//----------------------------

		//one-way platforms :)
		//note: though these handlers are pure, it's irrelevant whether they are marked pure
		//      or not as purity only effects sleeping when the return flag is *_ONCE
		
		var plat = new Body(BodyType.STATIC);
		plat.shapes.add(new Polygon(Polygon.rect(100,300-30,600,60)));
		plat.space = space;

		var platcb = new CbType();
		plat.cbType = platcb;

		//handler to deal with one-way platforms
		//don't have sum-types yet, so have to assign for all types we want to operate with one-way
		function oneway(arb:Arbiter) {
			if(!arb.isCollisionArbiter()) return PreFlag.ACCEPT;
				
			var rev = arb.body2.cbType==platcb; //reverse direction logic if objects are opposite to what we expect.
			var dir = new Vec2(0,rev ? 1 : -1);

			return if(dir.dot(arb.collisionArbiter.normal)>=0) PreFlag.ACCEPT else PreFlag.IGNORE;
		}

		for(cb in [hexcb,boxcb])
			space.listeners.add(new PreListener(platcb,cb,oneway));

		run(function (dt) {
			hand.anchor1.setxy(mouseX,mouseY);

			debug.clear();
			space.step(dt,10,10);
			debug.draw(space);
			debug.flush();
		});
	}
}
