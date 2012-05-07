package;

import FixedStep;

import nape.space.Space;
import nape.util.BitmapDebug;

import nape.phys.Body;
import nape.phys.BodyType;
import nape.phys.FluidProperties;
import nape.phys.Interactor;
import nape.phys.Compound;

import nape.shape.Circle;
import nape.shape.Polygon;

import nape.dynamics.Arbiter;
import nape.dynamics.Contact;
import nape.geom.Vec2;

import nape.callbacks.ConstraintListener;
import nape.callbacks.InteractionListener;
import nape.callbacks.BodyListener;
import nape.callbacks.PreListener;

import nape.callbacks.ConstraintCallback;
import nape.callbacks.InteractionCallback;
import nape.callbacks.BodyCallback;
import nape.callbacks.PreCallback;

import nape.callbacks.InteractionType;

import nape.callbacks.PreFlag;
import nape.callbacks.CbType;
import nape.callbacks.OptionType;
import nape.callbacks.CbEvent;

import nape.constraint.PivotJoint;
import nape.constraint.Constraint;

class Callbacks extends FixedStep {
	static function main() {
		new Callbacks();
	}

	public function new() {
		super(1/60);

		var space = new Space(new Vec2(0,400));
		var debug = new BitmapDebug(stage.stageWidth,stage.stageHeight,0x333333,false);
		debug.drawCollisionArbiters = true;
		debug.drawConstraints = true;
		addChild(debug.display);

		var hand = new PivotJoint(space.world,space.world,new Vec2(),new Vec2());
		hand.stiff = false;
		hand.space = space;
		hand.active = false;

		var prel:PreListener = null;
		var oneway_platform = new CbType();
		addEventListener(flash.events.MouseEvent.MOUSE_DOWN, function(_) {
			prel.options2.include(oneway_platform);
			prel.options2.exclude(oneway_platform);
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
		//CbTypes

		//partial penetration
		var partial_penetration = new CbType();

		//one-way platforms
		var oneway_object = new CbType(); //objects that can interact with oneway_platforms

		//sleep indication
		var indicate_sleep = new CbType();
		//touch indication
		var indicate_touch = new CbType();

		//breakapart constraint compound
		var breakup_compound = new CbType();

		//--------------------

		for(i in 0...10) {
			var pent = new Body();
			var shape = new Polygon(Polygon.regular(80,80,5));
			shape.body = pent;
			pent.position.setxy(800/11*(i+1),150);
			pent.space = space;
			
			//set it's cbTypes
			shape.cbTypes.add(partial_penetration);
			pent.cbTypes.add(oneway_object);
		}

		//aaand set up the pre-listener to do the partial penetration magic fun times.
		// note: this is a pure function with respect to the two objects
		//       (it's output doesn't change) so we can tell nape this and allow objects
		//       to sleep as normal.
		space.listeners.add(prel = new PreListener(InteractionType.COLLISION,partial_penetration,OptionType.ANY_SHAPE,function(cb:PreCallback) {
			var depth = 15;

			//to allow penetration, we need to both change contact penetrations,
			//and arbiter radius by same amount.
			var carb = cb.arbiter.collisionArbiter;
			carb.contacts.filter(function (c:Contact):Bool {
				//discard if not deep enough.
				if(c.penetration <= depth) return false;

				c.penetration -= depth;
				return true;
			});
			carb.radius -= depth;

			//another handler may have come in already.
			//we simply make sure we return current state + IGNORE
			if(cb.arbiter.state == PreFlag.IGNORE) return PreFlag.IGNORE_ONCE;
			else if(cb.arbiter.state == PreFlag.ACCEPT) return PreFlag.ACCEPT_ONCE;
			else return null;
		},1, //precedence of 1 (higher than default 0) so that one-way platform check occurs AFTER!
		true //pure
		));

		//----------------------------

		var boxes = [];
		for(i in 0...10) {
			var box = new Body();
			box.shapes.add(new Polygon(Polygon.box(40,40)));
			box.position.setxy(800/11*(i+1),100);
			boxes.push(box);
			//note box isn't added to space (# see few lines below)
			
			//set it's cbTypes
			box.cbTypes.add(indicate_touch);
		}

		for(i in 0...5) {
			var b1 = boxes[i*2];
			var b2 = boxes[i*2+1];
		
			var compound = new Compound();
			b1.compound = b2.compound = compound;
			
			var mid = b1.position.add(b2.position).mul(0.5);
			var link = new PivotJoint(b1,b2,b1.worldToLocal(mid),b2.worldToLocal(mid));
			link.compound = compound;
			link.maxError = 5; //px
			link.breakUnderError = true;
			link.removeOnBreak = true;
			link.cbTypes.add(breakup_compound);

			// (#) <-- because it is added to the space via it's compound instead.
			// see also that the link constraint is not directly added to the space.
			compound.space = space;
			compound.cbTypes.add(oneway_object);
		}

		//setup listeners
		function boxer(colour:Int) { 
			return function(cb:InteractionCallback) {
				//we gave the box bodies the cbType, rather than the shapes so we 'know'
				//we need to use interactor.body and not interator.shape
			
				//draw thick line using a quad.
				var p1 = cb.int1.castBody.position;
				var p2 = cb.int2.castBody.position;
				var n = p1.sub(p2);
				n.length=1; n.angle += Math.PI/2;
	
				debug.drawFilledPolygon([p1.sub(n,true),p2.sub(n,true),p2.add(n,true),p1.add(n,true)],colour);
			};
		}

		space.listeners.add(new InteractionListener(CbEvent.BEGIN, InteractionType.COLLISION, indicate_touch,indicate_touch, boxer(0x00ff00)));
		space.listeners.add(new InteractionListener(CbEvent.END,   InteractionType.COLLISION, indicate_touch,indicate_touch, boxer(0xff0000)));

		space.listeners.add(new ConstraintListener(CbEvent.BREAK, breakup_compound, function (cb:ConstraintCallback) {
			//We're going to break apart the compound containing the constraint and the two boxes
			//we set the constraint to be removed when it broke, so we don't need to remove the constraint
			// - When removed, it is also removed from the compound treating it as though it is completely deleted.
			var link = cast(cb.constraint,PivotJoint);
			var b1 = link.body1; var b2 = link.body2;
			b1.compound.breakApart();
			//now that the compound is broken up, we want each box inside to be a oneway_object
			b1.cbTypes.add(oneway_object);
			b2.cbTypes.add(oneway_object);
		}));
		//----------------------------

		for(i in 0...10) {
			var circ = new Body();
			circ.shapes.add(new Circle(15));
			circ.position.setxy(800/11*(i+1),50);
			circ.space = space;
			
			//set it's cbTypes
			circ.cbTypes.add(indicate_sleep);
			circ.cbTypes.add(oneway_object);
		}

		//and set up listeners
		function circler(colour:Int) {
			return function(cb:BodyCallback) {
				for(shape in cb.body.shapes) {
					if(shape.isCircle()) debug.drawFilledCircle(shape.worldCOM,shape.castCircle.radius,colour);
					else debug.drawFilledPolygon(shape.castPolygon.worldVerts,colour);
				}
			}
		}
		space.listeners.add(new BodyListener(CbEvent.WAKE,  indicate_sleep, circler(0x00ff00)));
		space.listeners.add(new BodyListener(CbEvent.SLEEP, indicate_sleep, circler(0xff0000)));

		//----------------------------

		//one-way platforms :)
		//note: though these handlers are pure, it's irrelevant whether they are marked pure
		//      or not as purity only effects sleeping when the return flag is *_ONCE
		
		var plat = new Body(BodyType.STATIC);
		plat.shapes.add(new Polygon(Polygon.rect(100,300-30,600,60)));
		plat.space = space;

		plat.cbTypes.add(oneway_platform);

		//handler to deal with one-way platforms
		//don't have sum-types yet, so have to assign for all types we want to operate with one-way
		function oneway(cb:PreCallback) {
			var dir = new Vec2(0,cb.swapped ? 1 : -1);

			//return null so that whatever PreFlag is already set is kept
			//allows this to work in conjunction with other PreListeners that may come before.
			return if(dir.dot(cb.arbiter.collisionArbiter.normal)>=0) null else PreFlag.IGNORE;
		}

		space.listeners.add(new PreListener(InteractionType.COLLISION, oneway_platform,oneway_object,oneway));

		run(function (dt) {
			hand.anchor1.setxy(mouseX,mouseY);

			debug.clear();
			space.step(dt,10,10);
			debug.draw(space);
			debug.flush();
		});
	}
}
