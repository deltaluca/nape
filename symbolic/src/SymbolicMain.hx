package;

import symbolic.Expr;
using symbolic.Expr.ExprUtils;

class SymbolicMain {
	static function bodyContext(context:Context, body:Int) {
		context.variableContext("pos"+body,etVector,eVariable("vel"+body));
		context.variableContext("vel"+body,etVector);
		context.variableContext("rot"+body,etScalar,eVariable("angvel"+body));
		context.variableContext("angvel"+body,etScalar);
		context.variableContext("imass"+body,etScalar);
		context.variableContext("iinertia"+body,etScalar);
	}

	static var txt:flash.text.TextField;
	public static function tracex(x:Dynamic) {
		txt.text += Std.string(x)+"\n";
	}
	static function main() {
		txt = new flash.text.TextField();
		var c = flash.Lib.current.stage;
		c.addChild(txt);
		txt.width = c.stageWidth;
		txt.height = c.stageHeight;
		txt.wordWrap = true;


		var context = ExprUtils.emptyContext();
		context.variableContext("anchor1",etVector);
		context.variableContext("anchor2",etVector);
		context.variableContext("dist",etScalar);
		bodyContext(context,1);
		bodyContext(context,2);

/*		var expr = eLet(
			"a",eCross(eScalar(10),eVariable("pos1")),
			eOuter(eVariable("a"),eVariable("a"))
		);

		tracex(expr.print());*/
	
		function wrap(e:Expr) {
			return
			eLet("pos1",eVector(1,2),
			eLet("pos2",eVector(2,1),
			eLet("rot1",eScalar(Math.PI*0.5),
			eLet("rot2",eScalar(Math.PI),
			eLet("vel1",eVector(10,20),
			eLet("vel2",eVector(20,10),
			eLet("angvel1",eScalar(1),
			eLet("angvel2",eScalar(-1),
			eLet("anchor1",eVector(1,0),
			eLet("anchor2",eVector(0,1),
				e
			))))))))));
		}

		var dvec = eAdd(eAdd(eVariable("pos2"),eRelative("rot2",eVariable("anchor2"))),eMul(eScalar(-1),eAdd(eVariable("pos1"),eRelative("rot1",eVariable("anchor1")))));

		var dist = eAdd(eMag(dvec), eMul(eScalar(-1),eVariable("dist")));
	
//		var dist = eLet("dvec",dvec,eAdd(eMag(eVariable("dvec")),eMul(eScalar(-1),eVariable("dist"))));

	//-------------

		var working = dist;
		tracex("C(.) = "+working.print());

		var workingV = working.diff(context);
		tracex("V(.) = "+workingV.print());

		var workingJv1x = workingV.diff(context,"vel1",0);
		tracex("Jv1_x(.) = "+workingJv1x.print());
		var workingJv1y = workingV.diff(context,"vel1",1);
		tracex("Jv1_y(.) = "+workingJv1y.print());
		var workingJw1 = workingV.diff(context,"angvel1");
		tracex("Jw1(.) = "+workingJw1.print());
		var workingJv2x = workingV.diff(context,"vel2",0);
		tracex("Jv2_x(.) = "+workingJv2x.print());
		var workingJv2y = workingV.diff(context,"vel2",1);
		tracex("Jv2_y(.) = "+workingJv2y.print());
		var workingJw2 = workingV.diff(context,"angvel2");
		tracex("Jw2(.) = "+workingJw2.print());
	/*
		var evalexpr = eLet(
			"pos1",eVector(1,20),
			expr
		);
		tracex(evalexpr.print());
		tracex(evalexpr.eval(context).print());

		var expr = eLet(
			"a",eRelative("rot1",eVariable("anchor1")),
			eLet("b",eVariable("a"),
				eOuter(eVariable("b"),eUnit(eVariable("a")))
			)
		);
		tracex(expr.print());
		tracex(expr.diff(context).print());
		tracex(wrap(expr).eval(context).print());
		tracex(wrap(expr.diff(context)).eval(context).print());*/
	}
/*
	static function main() {
		var space = new nape.space.Space();

		var b1 = new nape.phys.Body();
		b1.shapes.add(new nape.shape.Circle(20));
		var b2 = new nape.phys.Body(nape.phys.BodyType.KINEMATIC);
		b2.shapes.add(new nape.shape.Circle(20));

		b1.shapes.at(0).filter = new nape.dynamics.InteractionFilter(1,2);
		b2.shapes.at(0).filter = new nape.dynamics.InteractionFilter(2,1);

		b1.space = b2.space = space;

		b1.cbType = new nape.callbacks.CbType();
		b2.cbType = new nape.callbacks.CbType();

		space.listeners.add(new nape.callbacks.InteractionListener(nape.callbacks.CbEvent.BEGIN, nape.callbacks.InteractionType.COLLISION, b1.cbType, b2.cbType, function (cb) { trace(cb); }));
		
		space.step(1);
	}*/
}
