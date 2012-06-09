package {
	import nape.space.Space;
	import nape.util.BitmapDebug;

	import nape.phys.Body;
	import nape.geom.Vec2;
	import nape.phys.BodyType;
	import nape.phys.BodyList;

	import nape.shape.Circle;
	import nape.shape.Polygon;

	import nape.dynamics.InteractionFilter;
	import nape.dynamics.InteractionGroup;

	import nape.constraint.PivotJoint;

	import FixedStep;

	import flash.events.Event;
	import flash.events.MouseEvent;

	[SWF(width='600',height='450',backgroundColor='#333333',frameRate='60')]

	public class Filtering extends FixedStep {
		public function Filtering():void {
			if(stage!=null) init(null);
			else addEventListener(Event.ADDED_TO_STAGE,init);
		}
		public function init(ev:Event):void {
			if(ev!=null) removeEventListener(Event.ADDED_TO_STAGE,init);
			super.init_fps(stage, 1/60);

			var space:Space = new Space(new Vec2(0,400));
			var debug:BitmapDebug = new BitmapDebug(stage.stageWidth,stage.stageHeight,0x333333);
			addChild(debug.display);

			var hand:PivotJoint = new PivotJoint(space.world,null,new Vec2(),new Vec2());
			hand.active = false;
			hand.stiff = false;
			hand.space = space;
			
			stage.addEventListener(MouseEvent.MOUSE_DOWN, function (ev:Event):void {
				var mp:Vec2 = new Vec2(mouseX,mouseY);
				var bodies:BodyList = space.bodiesUnderPoint(mp);
				for(var i:int = 0; i<bodies.length; i++) {
					var b:Body = bodies.at(i);
					if(!b.isDynamic()) continue;
					hand.body2 = b;
					hand.anchor2 = b.worldToLocal(mp);
					hand.active = true;
					break;
				}
			});
			stage.addEventListener(MouseEvent.MOUSE_UP, function (ev:Event):void {
				hand.active = false;
			});

			//------------------------------------------------------------

			var border:Body = new Body(BodyType.STATIC);
			border.shapes.add(new Polygon(Polygon.rect(0,0,-50,stage.stageHeight)));
			border.shapes.add(new Polygon(Polygon.rect(stage.stageWidth,0,50,stage.stageHeight)));
			border.shapes.add(new Polygon(Polygon.rect(0,0,stage.stageWidth,-50)));
			border.shapes.add(new Polygon(Polygon.rect(0,stage.stageHeight,stage.stageWidth,50)));

			border.shapes.add(new Polygon(Polygon.rect(0,stage.stageHeight/2-20,stage.stageWidth,40)));
			border.space = space;

			//------------------------------------------------------------

			//circles that collide with everything but themselves.
			//using InteractionFilter
			for(var i:int = 0; i<10; i++) {
				var b:Body = new Body(BodyType.DYNAMIC, new Vec2((i+1)*stage.stageWidth/11,50));
				var c:Circle = new Circle(20);
				c.filter.collisionGroup = 2; //in group 0x00000002
				c.filter.collisionMask = ~2; //collide with everything in groups 0xfffffffd
				c.body = b;
				b.space = space;
			}

			//hexagons that collide with everything but themselves.
			//using InteractionGroup (simpler to reason about, but less powerful)
			var group:InteractionGroup = new InteractionGroup();
			group.ignore = true;
			for(i = 0; i<10; i++) {
				b = new Body(BodyType.DYNAMIC, new Vec2((i+1)*stage.stageWidth/11,150));
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
			var rootgroup:InteractionGroup = new InteractionGroup();
			rootgroup.ignore = true;

			var boxgroup:InteractionGroup  = new InteractionGroup(); boxgroup.group  = rootgroup;
			var circgroup:InteractionGroup = new InteractionGroup(); circgroup.group = rootgroup;

			for(i = 0; i<10; i++) {
				b = new Body(BodyType.DYNAMIC, new Vec2((i+1)*stage.stageWidth/11,300));
				b.shapes.add(new Polygon(Polygon.box(40,40)));
				b.group = boxgroup; //again could use Shapes instead
				b.space = space;
		
				b = new Body(BodyType.DYNAMIC, new Vec2((i+1)*stage.stageWidth/11,400));
				b.shapes.add(new Circle(20));
				b.group = circgroup;
				b.space = space;
			}

			//------------------------------------------------------------

			run(function (dt:Number):void {
				hand.anchor1.setxy(mouseX,mouseY);

				debug.clear();
				space.step(dt,10,10);
				debug.draw(space);
				debug.flush();
			});
		}
	}
}
