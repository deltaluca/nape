package {

import flash.display.Sprite;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.ui.Keyboard;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.utils.getTimer;

import Box2D.Dynamics.b2World; 
import Box2D.Common.Math.b2Vec2;
import Box2D.Dynamics.b2Fixture;
import Box2D.Dynamics.b2Body;
import Box2D.Dynamics.b2BodyDef;
import Box2D.Dynamics.b2FixtureDef;
import Box2D.Collision.Shapes.b2PolygonShape;

[SWF(width="500", height="500", frameRate="120", backgroundColor="#333333")]
public class Main extends Sprite {
	public function Main():void {
		super();
		if(stage!=null) init();
		else addEventListener(Event.ADDED_TO_STAGE,init);
	}

	private const scale:Number = 30;
	private const boxw:Number = 6;
	private const boxh:Number = 12;
	private const _height:int = 40;
	
	private var render:Boolean = true;
	private var txt:TextField;
	private var world:b2World;
	private var bodies:Vector.<b2Body> = new Vector.<b2Body>();
	private function init(ev:Event=null):void {
		if(ev!=null) removeEventListener(Event.ADDED_TO_STAGE,init);

		txt = new TextField();
		txt.defaultTextFormat = new TextFormat(null,14,0xffffff);
		addChild(txt);

		world = new b2World(new b2Vec2(0.0,400/scale),true);

		var borderdef:b2BodyDef = new b2BodyDef();
		var border:b2Body = world.CreateBody(borderdef);

		var p0:b2PolygonShape = new b2PolygonShape();
		p0.SetAsOrientedBox(50/scale/2,500/scale/2,new b2Vec2(-25/scale,250/scale),0);
		var p1:b2PolygonShape = new b2PolygonShape();
		p1.SetAsOrientedBox(50/scale/2,500/scale/2,new b2Vec2(525/scale,250/scale),0);
		var p2:b2PolygonShape = new b2PolygonShape();
		p2.SetAsOrientedBox(500/scale/2,50/scale/2,new b2Vec2(250/scale,-25/scale),0);
		var p3:b2PolygonShape = new b2PolygonShape();
		p3.SetAsOrientedBox(500/scale/2,50/scale/2,new b2Vec2(250/scale,525/scale),0);

		border.CreateFixture2(p0,0);
		border.CreateFixture2(p1,0);
		border.CreateFixture2(p2,0);
		border.CreateFixture2(p3,0);

		for(var y:int = 1; y<=_height; y++) {
			for(var x:int = 0; x<y; x++) {
				var blockdef:b2BodyDef = new b2BodyDef();
				blockdef.type = b2Body.b2_dynamicBody;
				blockdef.position.Set(
					(250-boxw*(y-1)*0.5+(x)*boxw)/scale,
					(500-boxh*0.5-boxh*(_height-y)*0.98)/scale
				);
				var block:b2Body = world.CreateBody(blockdef);
				bodies.push(block);
				var box:b2PolygonShape = new b2PolygonShape();
				box.SetAsBox(boxw/scale/2.0,boxh/scale/2.0);
				var fixture:b2FixtureDef = new b2FixtureDef;
				fixture.shape = box;
				fixture.density = 1;
				fixture.friction = 0.3;
				block.CreateFixture(fixture);
			}
		}

		addEventListener(Event.ENTER_FRAME, loop);
		stage.addEventListener(KeyboardEvent.KEY_DOWN, keyboard);
	}

	private function keyboard(ev:KeyboardEvent):void {
		if(ev.keyCode==Keyboard.SPACE) render = !render;
	}

	private var pt:int = getTimer();
	private var fps:Number = -1.0;
	private var timeStamp:int = 0;
	private function loop(ev:Event):void {
		var ct:int = getTimer();
		var nfps:Number = 1000/(ct-pt);
		fps = fps==-1.0 ? nfps : fps*0.95+nfps*0.05;
		pt = ct;
		txt.text = fps.toString().substr(0,5)+"fps";

		var dt:Number = Math.min(1/40,1/200+timeStamp*1e-5*30);

		world.Step(dt,8,8);
		timeStamp++;

		graphics.clear();
		if(render) {
			var i:int = 0;
			for each(var b:b2Body in bodies) {
				var rgb:int = int(0xffffff*Math.exp(-(i++)%500)/1500);
				graphics.lineStyle(0.1,rgb,1);
				var vert:b2Vec2, vert2:b2Vec2;
				vert = vert2 = b.GetWorldPoint(new b2Vec2(boxw/2/scale,boxh/2/scale));
				graphics.moveTo(vert.x*scale,vert.y*scale);
				vert = b.GetWorldPoint(new b2Vec2(-boxw/2/scale,boxh/2/scale));
				graphics.lineTo(vert.x*scale,vert.y*scale);
				vert = b.GetWorldPoint(new b2Vec2(-boxw/2/scale,-boxh/2/scale));
				graphics.lineTo(vert.x*scale,vert.y*scale);
				vert = b.GetWorldPoint(new b2Vec2(boxw/2/scale,-boxh/2/scale));
				graphics.lineTo(vert.x*scale,vert.y*scale);
				graphics.lineTo(vert2.x*scale,vert2.y*scale);
			}
		}
	}
}
}
