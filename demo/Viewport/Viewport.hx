package;

import nape.space.Space;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.shape.Circle;
import nape.shape.Polygon;
import nape.geom.Vec2;
import nape.util.BitmapDebug;
import nape.dynamics.InteractionFilter;
import nape.phys.Compound;
import nape.callbacks.CbType;
import nape.callbacks.CbEvent;
import nape.callbacks.InteractionType;
import nape.callbacks.InteractionListener;
import nape.util.Debug;
import nape.constraint.MotorJoint;
import nape.constraint.PivotJoint;

import FixedStep;

class Viewport extends FixedStep {
	static function main() new Viewport()
	function new() {
		super(1/60);

		var space = new Space(new Vec2(0,0));
		var debug = new BitmapDebug(stage.stageWidth, stage.stageHeight, 0x333333);
		addChild(debug.display);

		//=================================================================================
		//viewport compound (we can have multiple 'cameras')
		var viewport = new Compound();
		var VIEWPORT = new CbType();
		viewport.cbTypes.add(VIEWPORT);
		viewport.space = space;

		//called when a body has entered any part of viewport.
		space.listeners.add(
		new InteractionListener(CbEvent.BEGIN, InteractionType.SENSOR, VIEWPORT, CbType.ANY_BODY, function (cb) {
			var new_body = cb.int2.castBody;
			if(new_body.compound==viewport) return; //ignore viewport bodies.

			new_body.graphic.alpha = 1.0;
		}));

		//called when a body has left any part of viewport.
		space.listeners.add(
		new InteractionListener(CbEvent.END, InteractionType.SENSOR, VIEWPORT, CbType.ANY_BODY, function (cb) {
			var old_body = cb.int2.castBody;
			if(old_body.compound==viewport) return; //ignore viewport bodies.

			old_body.graphic.alpha = 0.25;
		}));

		//------------------------------------------------------
		//first camera.
		var camera = new Body();
		camera.position.setxy(150,100);
		camera.shapes.add(new Polygon(Polygon.box(200,150)));
		camera.setShapeFilters(new InteractionFilter(0,0,-1,1,0,0)); //only sense with everything!
		camera.compound = viewport;

		function apply_friction(camera:Body) {
			//abuse PivotJoint + MotorJoint for friction
			var friction = new PivotJoint(space.world, camera, new Vec2(), new Vec2());
			friction.compound = viewport;
			friction.stiff = false;
			friction.maxError = 0;
			friction.maxForce = 1e+6;

			var angfric = new MotorJoint(space.world, camera, 0);
			angfric.compound = viewport;
			angfric.maxForce = 1e+7;
		}
		apply_friction(camera);

		//------------------------------------------------------
		//second camera

		var camera = new Body();
		camera.position.setxy(450,300);
		camera.shapes.add(new Polygon(Polygon.regular(200,200,5)));
		camera.setShapeFilters(new InteractionFilter(0,0,-1,1,0,0)); //only sense with everything!
		camera.compound = viewport;

		apply_friction(camera);

		//=================================================================================
		//border body
		
		var border = new Body(BodyType.STATIC);
		border.shapes.add(new Polygon(Polygon.rect(0,0,-50,stage.stageHeight)));
		border.shapes.add(new Polygon(Polygon.rect(stage.stageWidth,0,50,stage.stageHeight)));
		border.shapes.add(new Polygon(Polygon.rect(0,0,stage.stageWidth,-50)));
		border.shapes.add(new Polygon(Polygon.rect(0,stage.stageHeight,stage.stageWidth,50)));
		border.space = space;

		//=================================================================================
		//viewable bodies

		for(i in 0...100) {
			var b = new Body();
			b.position.setxy(Math.random()*800,Math.random()*600);
			b.shapes.add(new Polygon(Polygon.regular(Math.random()*20+20,Math.random()*20+20,Std.int(Math.random()*2)+3)));
			b.space = space;

			b.graphic = Debug.createGraphic(b);
			addChild(b.graphic);
			b.graphic.alpha = 0.25;
		}

		//=================================================================================
		//grabby grabby

		var hand = new PivotJoint(space.world,null,new Vec2(), new Vec2());
		hand.active = false;
		hand.space = space;
		hand.stiff = false;
		
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
		stage.addEventListener(flash.events.MouseEvent.MOUSE_UP, function (_) hand.active = false);

		//=================================================================================

		run(function (dt) {
			debug.clear();
			hand.anchor1.setxy(mouseX,mouseY);
			space.step(dt);
			debug.draw(viewport);
			debug.flush();
		});
	}
}

