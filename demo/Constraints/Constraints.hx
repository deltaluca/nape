package;

import nape.space.Space;
#if flash10
    import nape.util.BitmapDebug;
#else
    import nape.util.ShapeDebug;
#end
import nape.geom.Vec2;

import nape.phys.Body;
import nape.phys.BodyType;
import nape.phys.FluidProperties;

import nape.shape.Circle;
import nape.shape.Polygon;

import nape.constraint.AngleJoint;
import nape.constraint.DistanceJoint;
import nape.constraint.LineJoint;
import nape.constraint.MotorJoint;
import nape.constraint.PivotJoint;
import nape.constraint.WeldJoint;

import FixedStep;

typedef DEBUG = #if flash10 BitmapDebug #else ShapeDebug #end;

class Constraints extends FixedStep {
	static function main() {
        #if nme
            nme.Lib.create(
                function() { new Constraints(); },
                1200, 600,
                60,
                0x333333,
                nme.Lib.HARDWARE | nme.Lib.VSYNC,
                "Constraints"
            );
        #else
    		new Constraints();
        #end
	}

	function new() {
		super(1/60);

		var debug = new DEBUG(stage.stageWidth,stage.stageHeight,0x333333);
		debug.drawConstraints = true;
		addChild(debug.display);

		var space = new Space(new Vec2());

		//borders
		var th = 10; var cell = 300;
		var border = new Body(BodyType.STATIC);
		function gen(x:Int,y:Int) {
			var rx = cell*x-th/2; var ry = cell*y-th/2;
			border.shapes.add(new Polygon(Polygon.rect(rx,ry,th,cell+th)));
			border.shapes.add(new Polygon(Polygon.rect(rx+cell,ry,th,cell+th)));
			border.shapes.add(new Polygon(Polygon.rect(rx,ry,cell+th,th)));
			border.shapes.add(new Polygon(Polygon.rect(rx,ry+cell,cell+th,th)));
		}
		gen(1,0); gen(2,0); gen(3,0);
		gen(0,1); gen(1,1); gen(2,1);
		gen(3,1);
		border.space = space;

		function mid(x:Int,y:Int) {
			var rx = cell*x+th/2; var ry = cell*(y+0.5)-th/2;
			var b = new Body(BodyType.STATIC);
			b.shapes.add(new Polygon(Polygon.rect(rx,ry,cell-th,th)));
			b.space = space;
		}

		//mouse-control
		var hand = new PivotJoint(space.world,space.world,new Vec2(), new Vec2());
		hand.space = space;
		hand.active = false;
		hand.stiff = false;

		stage.addEventListener(flash.events.MouseEvent.MOUSE_DOWN, function(_) {
			var mp = new Vec2(mouseX,mouseY);
			for(b in space.bodiesUnderPoint(mp)) {
				if(!b.isDynamic()) continue;
				hand.body2 = b;
				hand.anchor2 = b.worldToLocal(mp);
				hand.active = true;
				break;
			}
		});
		stage.addEventListener(flash.events.MouseEvent.MOUSE_UP, function(_) {
			hand.active = false;
		});

		function description(x:Int,y:Int,desc:String,top=false) {
			var txt = new flash.text.TextField();
			txt.x = cell*x+th/2;
			txt.y = if(top) cell*y+th/2 else cell*(y+1)-th/2-16;
			txt.width = cell-th;
			txt.selectable = false;

			var tf = new flash.text.TextFormat(null,14,0xcccccc);
			txt.defaultTextFormat = tf;

			addChild(txt);
			txt.text = desc;
			return txt;
		}

		//softness description
		var txt = description(0,0,"for applicable constraints\ntop is stiff\nbottom is soft");
		txt.y = 100;
		txt.x = 80;

		//constraints-----------------------------

		//note: we don't use 'allowMovement = false' as this
		//      doesn't play nicely with PivotJoint for 'hand'
		function fix(b:Body) {
			var mp = new PivotJoint(space.world,b,b.position,new Vec2());
			mp.space = space;
		}

		function circle(x,y,r) {
			var b = new Body();
			b.shapes.add(new Circle(r));
			b.position.setxy(x,y);
			b.space = space;
			return b;
		}

		//AngleJoint --------------------------------
		mid(1,0);

		var b1 = circle(cell+cell/3,cell/4,35);
		var b2 = circle(cell+cell*2/3,cell/4,35);
		fix(b1); fix(b2);

		var angle = new AngleJoint(b1,b2,-Math.PI,2*Math.PI);
		angle.ratio = 3;
		angle.space = space;

		var b1 = circle(cell+cell/3,cell*3/4,35);
		var b2 = circle(cell+cell*2/3,cell*3/4,35);
		fix(b1); fix(b2);

		var angle = new AngleJoint(b1,b2,-Math.PI,2*Math.PI);
		angle.ratio = 3;
		angle.stiff = false;
		angle.frequency = 0.5;
		angle.space = space;

		description(1,0,"AngleJoint",true);
		description(1,0,"min = -(max = pi/2),  ratio = 3");

		//MotorJoint ---------------------------------

		var b1 = circle(cell*2+cell/3,cell/2,25);
		var b2 = circle(cell*2+cell*2/3,cell/2,25);
		fix(b1); fix(b2);

		var motor = new MotorJoint(b1,b2,10,3);
		motor.space = space;

		description(2,0,"MotorJoint",true);
		description(2,0,"rate = 10,  ratio = 3");

		//DistanceJoint ------------------------------
		mid(3,0);

		var b1 = circle(cell*3+cell/3,cell/4,20);
		var b2 = circle(cell*3+cell*2/3,cell/4,20);

		var dist = new DistanceJoint(b1,b2,new Vec2(20,0),new Vec2(-20,0),40,80);
		dist.space = space;

		var b1 = circle(cell*3+cell/3,cell*3/4,20);
		var b2 = circle(cell*3+cell*2/3,cell*3/4,20);

		var dist = new DistanceJoint(b1,b2,new Vec2(20,0),new Vec2(-20,0),40,80);
		dist.stiff = false;
		dist.frequency = 0.5;
		dist.space = space;

		description(3,0,"DistanceJoint",true);
		description(3,0,"min = 40,  max = 60");

		//PivotJoint ---------------------------------
		mid(0,1);

		var b1 = circle(cell/3,cell+cell/4,20);
		var b2 = circle(cell*2/3,cell+cell/4,20);

		var mi = new Vec2(cell/2,cell+cell/4);
		var pivot = new PivotJoint(b1,b2,b1.worldToLocal(mi),b2.worldToLocal(mi));
		pivot.space = space;

		var b1 = circle(cell/3,cell+cell*3/4,20);
		var b2 = circle(cell*2/3,cell+cell*3/4,20);

		var mi = new Vec2(cell/2,cell+cell*3/4);
		var pivot = new PivotJoint(b1,b2,b1.worldToLocal(mi),b2.worldToLocal(mi));
		pivot.stiff = false;
		pivot.frequency = 0.5;
		pivot.space = space;

		description(0,1,"PivotJoint",true);

		//WeldJoint -----------------------------------
		mid(1,1);

		var b1 = circle(cell+cell/3,cell+cell/4,20);
		var b2 = circle(cell+cell*2/3,cell+cell/4,20);

		var mi = new Vec2(cell+cell/2,cell+cell/4);
		var pivot = new WeldJoint(b1,b2,b1.worldToLocal(mi),b2.worldToLocal(mi));
		pivot.space = space;

		var b1 = circle(cell+cell/3,cell+cell*3/4,20);
		var b2 = circle(cell+cell*2/3,cell+cell*3/4,20);

		var mi = new Vec2(cell+cell/2,cell+cell*3/4);
		var pivot = new WeldJoint(b1,b2,b1.worldToLocal(mi),b2.worldToLocal(mi));
		pivot.stiff = false;
		pivot.frequency = 0.5;
		pivot.space = space;

		description(1,1,"WeldJoint",true);
		description(1,1,"phase = 0");

		//LineJoint ------------------------------------
		mid(2,1);

		var b1 = circle(cell*2+cell/3,cell+cell/4,20);
		var b2 = circle(cell*2+cell*2/3,cell+cell/4,20);

		var mi = new Vec2(cell*2+cell/2,cell+cell/4);
		var line = new LineJoint(b1,b2,b1.worldToLocal(mi),b2.worldToLocal(mi),
			new Vec2(0,1),-20,20);
		line.space = space;

		var b1 = circle(cell*2+cell/3,cell+cell*3/4,20);
		var b2 = circle(cell*2+cell*2/3,cell+cell*3/4,20);

		var mi = new Vec2(cell*2+cell/2,cell+cell*3/4);
		var line = new LineJoint(b1,b2,b1.worldToLocal(mi),b2.worldToLocal(mi),
			new Vec2(0,1),-20,20);
		line.stiff = false;
		line.frequency = 0.5;
		line.space = space;

		description(2,1,"LineJoint",true);
		description(2,1,"dir = {0,1},  min = -(max = 20)");

		//Car -------------------------------------------

		//fluid to provide local gravity (lol)
		var grav = new Body(BodyType.STATIC);
		grav.shapes.add(new Polygon(Polygon.rect(
			cell*3+th/2,cell+th/2,cell-th,cell-th
		)));
		var s = grav.shapes.at(0);
		s.fluidEnabled = true;
		s.fluidProperties = new FluidProperties(2,0);
		s.fluidProperties.gravity = new Vec2(0,-400);
		grav.space = space;

		var body = new Body();
		body.shapes.add(new Polygon(Polygon.box(100,40)));
		body.position.setxy(cell*3+cell/2,cell+cell/2);
		body.space = space;

		var w1 = circle(cell*3+cell/2-50+20,cell+cell/2+20*2,20);
		var w2 = circle(cell*3+cell/2+50-20,cell+cell/2+20*2,20);

		var lin1 = new LineJoint(body,w1,new Vec2(-50,0),new Vec2(),
			new Vec2(0,1), 0,60);
		lin1.space = space;
		lin1.ignore = true; //prevent wheel colliding

		var lin2 = new LineJoint(body,w2,new Vec2(50,0), new Vec2(),
			new Vec2(0,1), 0,60);
		lin2.space = space;
		lin2.ignore = true; //prevent wheel colliding

		var spr1 = new DistanceJoint(body,w1,new Vec2(-50,-10), new Vec2(),40,40);
		spr1.stiff = false;
		spr1.frequency = 5;
		spr1.damping = 1;
		spr1.space = space;

		var spr2 = new DistanceJoint(body,w2,new Vec2(50,-10), new Vec2(),40,40);
		spr2.stiff = false;
		spr2.frequency = 5;
		spr2.damping = 1;
		spr2.space = space;

		var motor = new MotorJoint(space.world,w2,5);
		motor.space = space;

		description(3,1,"Car:\n\nSuspension = Line+soft Distance joints\n+MotorJoint with space.world at front",true);

		//!constraints----------------------------

		run(function(dt) {
			hand.anchor1.setxy(mouseX,mouseY);
			space.step(dt, 10,10);

			debug.clear();
			debug.draw(space);
			debug.flush();
		});
	}
}
