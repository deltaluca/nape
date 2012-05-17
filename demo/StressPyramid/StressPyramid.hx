package;

import nape.space.Space;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.shape.Polygon;
import nape.geom.Vec2;
import nape.util.BitmapDebug;
import nape.util.Debug;
import nape.space.Broadphase;
import nape.constraint.PivotJoint;

import VariableStep;
import FPS;

//we don't use FixedStep like other demos as this is a stress test
//and it's highly unlikely full speed is achievable and using FixedStep
//which enforces real time to match physics time would get us in a horrible
//spiral where it keeps calling space.step to keep up with real-time
//but doing so makes the fps drop even more and makes keeping up with real
//time ever more unachievable :P
class StressPyramid extends VariableStep {
	static function main() {
		new StressPyramid();
	}

	function new() {
		super();

		//sweep and prune is more suited to this sort of test
		//using dyn-aabb is not 'bad' (for me about 5fps lower when things are moving)
		//but not ideal since everything is moving a lot so the tree will be constantly rebuilt
		//versus sweep and prune where things aren't moving massively fast so is okay since world
		//is not huge.
		var space = new Space(new Vec2(0,400),Broadphase.SWEEP_AND_PRUNE);
		var debug = new BitmapDebug(stage.stageWidth,stage.stageHeight,0x333333);
		addChild(debug.display);
		debug.drawShapeAngleIndicators = false;

//		addChild(new FPS(stage.stageWidth,60,0,60,0x40000000,0xffffffff,0xa0ff0000));
		addChild(new Mem(stage.stageWidth,60,0,60,0x40000000,0xffffffff,0xa0ff0000));

		var border = new Body(BodyType.STATIC);
		border.shapes.add(new Polygon(Polygon.rect(0,0,-50,stage.stageHeight)));
		border.shapes.add(new Polygon(Polygon.rect(stage.stageWidth,0,50,stage.stageHeight)));
		border.shapes.add(new Polygon(Polygon.rect(0,0,stage.stageWidth,-50)));
		border.shapes.add(new Polygon(Polygon.rect(0,stage.stageHeight,stage.stageWidth,50)));
		border.space = space;

		var boxw = 6;
		var boxh = 12;
		var height = 40; //820 blocks

		for(y in 1...(height+1)) {
			for(x in 0...y) {
				var block = new Body();
				block.position.x = stage.stageWidth/2 - boxw*(y-1)/2 + x*boxw;
				//we give blocks y-position so that they're already overlapping a bit
				//since with the chain of allowed overlaps will mean 'ideal' position won't be satisfied.
				block.position.y = stage.stageHeight - boxh/2 - boxh*(height-y)*0.98;
				block.shapes.add(new Polygon(Polygon.box(boxw,boxh)));
				block.space = space;
			}
		}		

		//----------------------------------------------------------------------------------

		var hand = new PivotJoint(space.world,null,new Vec2(),new Vec2());
		hand.active = false;
		hand.stiff = false;
		hand.space = space;
		
		stage.addEventListener(flash.events.MouseEvent.MOUSE_DOWN, function (_) {
			var mp = new Vec2(mouseX,mouseY);
			for(b in space.bodiesUnderPoint(mp)) {
				if(!b.isDynamic()) continue;
				hand.body2 = b;
				hand.anchor2 = b.worldToLocal(mp);
				hand.active = true;
				break;
			}
		});
		stage.addEventListener(flash.events.MouseEvent.MOUSE_UP, function (_) {
			hand.active = false;
		});

		run(function (_) {
			//we start of simulation with a lower timestep to help with stability as all the contact constraints 'warm up'
			//  once the contacts are 'warm' the time-step will go to full speed and the pyramid will remain standing
			//without this the pyramid will simply tumble before the contacts have had time to settle towards a solution
			//  to the huge set of contact equations.
			var dt = Math.min(1/40, 1/200 + space.timeStamp*1e-5*30);

			hand.anchor1.setxy(mouseX,mouseY);
			debug.clear();
			space.step(dt,8,8);
			debug.draw(space);
			debug.flush();
		});
	}
}
