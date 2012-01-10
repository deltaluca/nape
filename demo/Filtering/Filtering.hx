package;

import nape.space.Space;
import nape.util.BitmapDebug;

import nape.phys.Body;
import nape.geom.Vec2;
import nape.phys.BodyType;

import nape.shape.Circle;
import nape.shape.Polygon;

import nape.dynamics.InteractionFilter;
import nape.dynamics.InteractionGroup;

import nape.constraint.PivotJoint;

import FixedStep;

class Filtering extends FixedStep {
	static function main() {
		new Filtering();
	}
	public function new() {
		super(1/60);

		var space = new Space(new Vec2(0,400));
		var debug = new BitmapDebug(stage.stageWidth,stage.stageHeight,0x333333);
		addChild(debug.display);

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

		//------------------------------------------------------------

		var border = new Body(BodyType.STATIC);
		border.shapes.add(new Polygon(Polygon.rect(0,0,-50,stage.stageHeight)));
		border.shapes.add(new Polygon(Polygon.rect(stage.stageWidth,0,50,stage.stageHeight)));
		border.shapes.add(new Polygon(Polygon.rect(0,0,stage.stageWidth,-50)));
		border.shapes.add(new Polygon(Polygon.rect(0,stage.stageHeight,stage.stageWidth,50)));

		border.shapes.add(new Polygon(Polygon.rect(0,stage.stageHeight/2-20,stage.stageWidth,40)));
		border.space = space;

		//------------------------------------------------------------

		//circles that collide with everything but themselves.
		//using InteractionFilter
		for(i in 0...10) {
			var b = new Body(BodyType.DYNAMIC, new Vec2((i+1)*stage.stageWidth/11,50));
			var c = new Circle(20);
			c.filter.collisionGroup = 2; //in group 0x00000002
			c.filter.collisionMask = ~2; //collide with everything in groups 0xfffffffd
			c.body = b;
			b.space = space;
		}

		//hexagons that collide with everything but themselves.
		//using InteractionGroup (simpler to reason about, but less powerful)
		var group = new InteractionGroup();
		group.ignore = true;
		for(i in 0...10) {
			var b = new Body(BodyType.DYNAMIC, new Vec2((i+1)*stage.stageWidth/11,150));
			b.shapes.add(new Polygon(Polygon.regular(40,40,6)));
			b.group = group; //we assign the body to the group, but we could also do it with shapes or a mixture
			b.space = space;
		}

		//------------------------------------------------------------

		//Using a small tree of interaction grops
		//so that the boxes will collide amongst themselves, as will the circles
		//but no box will collide with any circle.
		//
		//      rootgroup
		//     __|     |__
		//  boxgroup circgroup
		//
		//We could just as easily do this using the InteractionFilter's of the shapes
		//however using groups is more general as we do not need to 'use up' the limited number of values
		//available for InteractionFilter.
		var rootgroup = new InteractionGroup();
		rootgroup.ignore = true;

		var boxgroup  = new InteractionGroup(); boxgroup.group  = rootgroup;
		var circgroup = new InteractionGroup(); circgroup.group = rootgroup;

		for(i in 0...10) {
			var b = new Body(BodyType.DYNAMIC, new Vec2((i+1)*stage.stageWidth/11,300));
			b.shapes.add(new Polygon(Polygon.box(40,40)));
			b.group = boxgroup; //again could use Shapes instead
			b.space = space;
	
			var c = new Body(BodyType.DYNAMIC, new Vec2((i+1)*stage.stageWidth/11,400));
			c.shapes.add(new Circle(20));
			c.group = circgroup;
			c.space = space;
		}

		//------------------------------------------------------------

		run(function (dt) {
			hand.anchor1.setxy(mouseX,mouseY);

			debug.clear();
			space.step(dt,10,10);
			debug.draw(space);
			debug.flush();
		});
	}
}
