package {

import nape.space.Space;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.phys.Material;
import nape.shape.Polygon;
import nape.geom.Vec2;

import PhysicsData;

import flash.display.MovieClip;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.PixelSnapping;
import flash.events.Event;

[SWF(width="580", height="400", frameRate="60", backgroundColor="#333333")]
public class Main extends MovieClip {
	//graphical assets.
	[Embed(source="icecream.png")]  private var IceCream :Class;
	[Embed(source="hamburger.png")] private var Hamburger:Class;
	[Embed(source="drink.png")]     private var Drink    :Class;
	[Embed(source="orange.png")]    private var Orange   :Class;

	private function bitmap(bmp:Bitmap):Bitmap {
		bmp.pixelSnapping = PixelSnapping.AUTO;
		bmp.smoothing = true;
		return bmp;
	}
	//factory methods for building the PhysicsData bodies with their graphics.
	private function icecream ():Body { return PhysicsData.createBody("icecream", bitmap(new IceCream ())); }
	private function hamburger():Body { return PhysicsData.createBody("hamburger",bitmap(new Hamburger())); }
	private function drink    ():Body { return PhysicsData.createBody("drink",    bitmap(new Drink    ())); }
	private function orange   ():Body { return PhysicsData.createBody("orange",   bitmap(new Orange   ())); }

	public function Main():void {
		if(stage==null) init(null);
		else addEventListener(Event.ADDED_TO_STAGE,init);
	}

	private function init(ev:Event):void {
		if(ev!=null) removeEventListener(Event.ADDED_TO_STAGE,init);

		//create a new nape Space with gravity (0,600)
		var space:Space = new Space(new Vec2(0,600));

		//create the private border out of 3 rectangles
		var border:Body = new Body(BodyType.STATIC);
		border.shapes.add(new Polygon(Polygon.rect(0,-400,-40,stage.stageHeight+400)));
		border.shapes.add(new Polygon(Polygon.rect(stage.stageWidth,-400,40,stage.stageHeight+400)));
		border.shapes.add(new Polygon(Polygon.rect(0,stage.stageHeight,stage.stageWidth,40)));
		border.space = space;

		//register Material for the 'bouncy' ID from the .pes metadata
		PhysicsData.registerMaterial("bouncy", new Material(10));

		var factory:Array = [icecream,hamburger,drink,orange];
		var fall:Function = function():void {
			//generate a random one of our objects.
			var body:Body = factory[int(Math.random()*factory.length)]();
			addChild(body.graphic);
			body.space = space;

			//random position above stage
			body.position.setxy(Math.random()*(stage.stageWidth-100)+50,-200);
			body.rotation = Math.PI*2*Math.random();

			//rsemi-randomised velocity.
			body.velocity.y = 350;
			body.angularVel = Math.random()*10-5;
		};

		addEventListener(flash.events.Event.ENTER_FRAME, function(ev:Event):void {
			//until we have 30 objects, drop an object every 30 time steps
			if(space.timeStamp%30==0 && space.bodies.length<30) fall();

			//run simulation
			space.step(1/60);
		});
	}
}
}
