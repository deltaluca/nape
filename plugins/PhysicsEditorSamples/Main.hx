package;

import nape.space.Space;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.phys.Material;
import nape.shape.Polygon;
import nape.geom.Vec2;

import PhysicsData;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.PixelSnapping;

//graphical assets.
@:bitmap("icecream.png")  class IceCream  extends BitmapData {}
@:bitmap("hamburger.png") class Hamburger extends BitmapData {}
@:bitmap("drink.png")     class Drink     extends BitmapData {}
@:bitmap("orange.png")    class Orange    extends BitmapData {}

class Main {
	static function bitmap(bmp) return new Bitmap(bmp, PixelSnapping.AUTO, true)
	//factory methods for building the PhysicsData bodies with their graphics.
	static function icecream () return PhysicsData.createBody("icecream", bitmap(new IceCream (0,0)))
	static function hamburger() return PhysicsData.createBody("hamburger",bitmap(new Hamburger(0,0)))
	static function drink    () return PhysicsData.createBody("drink",    bitmap(new Drink    (0,0)))
	static function orange   () return PhysicsData.createBody("orange",   bitmap(new Orange   (0,0)))

	static function main() {
		var stage = flash.Lib.current.stage;
		//create a new nape Space with gravity (0,600)
		var space = new Space(new Vec2(0,600));

		//create the static border out of 3 rectangles
		var border = new Body(BodyType.STATIC);
		border.shapes.add(new Polygon(Polygon.rect(0,-400,-40,stage.stageHeight+400)));
		border.shapes.add(new Polygon(Polygon.rect(stage.stageWidth,-400,40,stage.stageHeight+400)));
		border.shapes.add(new Polygon(Polygon.rect(0,stage.stageHeight,stage.stageWidth,40)));
		border.space = space;

		//register Material for the 'bouncy' ID from the .pes metadata
		PhysicsData.registerMaterial("bouncy", new Material(10));

		var factory = [icecream,hamburger,drink,orange];
		function fall() {
			//generate a random one of our objects.
			var body = factory[Std.int(Math.random()*factory.length)]();
			stage.addChild(body.graphic);
			body.space = space;

			//random position above stage
			body.position.setxy(Math.random()*(stage.stageWidth-100)+50,-200);
			body.rotation = Math.PI*2*Math.random();

			//rsemi-randomised velocity.
			body.velocity.y = 350;
			body.angularVel = Math.random()*10-5;
		};

		stage.addEventListener(flash.events.Event.ENTER_FRAME, function(_) {
			//until we have 30 objects, drop an object every 30 time steps
			if(space.timeStamp%30==0 && space.bodies.length<30) fall();

			//run simulation
			space.step(1/60);
		});
	}
}
