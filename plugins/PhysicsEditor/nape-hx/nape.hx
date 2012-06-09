package;

import nape.phys.Body;
import nape.phys.BodyType;
import nape.shape.Shape;
import nape.shape.Polygon;
import nape.shape.Circle;
import nape.geom.Vec2;
import nape.dynamics.InteractionFilter;
import nape.phys.Material;
import nape.phys.FluidProperties;
import nape.callbacks.CbType;
import nape.callbacks.CbTypeList;
import nape.geom.AABB;

import flash.display.DisplayObject;

import StringTools;

class PhysicsData {

	public static function createBody(name:String,?graphic:DisplayObject):Body {
		var xret = lookup(name);
		if(graphic==null) return xret.body.copy();

		var ret = xret.body.copy();
		graphic.x = graphic.y = 0;
		graphic.rotation = 0;
		var bounds = graphic.getBounds(graphic);
		var offset = Vec2.get(bounds.x-xret.anchor.x, bounds.y-xret.anchor.y);

		ret.graphic = graphic;
        ret.graphicOffset = offset;

		return ret;
	}

	public static function registerMaterial(name:String,material:Material) {
		if(materials==null) materials = new Hash<Material>();
		materials.set(name,material);	
	}
	public static function registerFilter(name:String,filter:InteractionFilter) {
		if(filters==null) filters = new Hash<InteractionFilter>();
		filters.set(name,filter);
	}
	public static function registerFluidProperties(name:String,properties:FluidProperties) {
		if(fprops==null) fprops = new Hash<FluidProperties>();
		fprops.set(name,properties);
	}
	public static function registerCbType(name:String,cbType:CbType) {
		if(types==null) types = new Hash<CbType>();
		types.set(name,cbType);
	}

	//----------------------------------------------------------------------	

	static var bodies   :Hash<{body:Body,anchor:Vec2}>;
	static var materials:Hash<Material>;
	static var filters  :Hash<InteractionFilter>;
	static var fprops   :Hash<FluidProperties>;
	static var types    :Hash<CbType>;
	static inline function material(name:String):Material {
		if(name=="default") return new Material();
		else {
			if(materials==null || !materials.exists(name))
				throw "Error: Material with name '"+name+"' has not been registered";
			return materials.get(name);
		}
	}
	static inline function filter(name:String):InteractionFilter {
		if(name=="default") return new InteractionFilter();
		else {
			if(filters==null || !filters.exists(name))
				throw "Error: InteractionFilter with name '"+name+"' has not been registered";
			return filters.get(name);
		}
	}
	static inline function fprop(name:String):FluidProperties {
		if(name=="default") return new FluidProperties();
		else {
			if(fprops==null || !fprops.exists(name))
				throw "Error: FluidProperties with name '"+name+"' has not been registered";
			return fprops.get(name);
		}
	}
	static inline function cbtype(outtypes:CbTypeList, names:String) {
        for(namex in names.split(",")) {
            var name = StringTools.trim(namex);
            if(name=="") continue;

            if(!types.exists(name))
                throw "Error: CbType with name '"+name+"' has not been registered";
            outtypes.add(types.get(name));
        }
	}

	static inline function lookup(name:String) {
		if(bodies==null) init();
		if(!bodies.exists(name)) throw "Error: Body with name '"+name+"' does not exist";
		return bodies.get(name);
	}

	//----------------------------------------------------------------------	

	static function init() {
		bodies = new Hash<{body:Body,anchor:Vec2}>();

		{% for body in bodies %}
			var body = new Body();
            cbtype(body.cbTypes, "{{body.cbType}}");

			{% for fixture in body.fixtures %}
				var mat = material("{{fixture.material}}");
				var filt = filter("{{fixture.filter}}");
				var prop = fprop("{{fixture.fprop}}");

				{% if fixture.isCircle %}
					var s = new Circle(
						{{fixture.radius}},
						Vec2.weak({{fixture.center.x}},{{fixture.center.y}}),
						mat,
						filt
					);
					s.body = body;
					s.fluidEnabled = {{fixture.fluidEnabled}};
					s.fluidProperties = prop;
                    cbtype(s.cbTypes, "{{fixture.cbType}}");
				{% else %}
					{% for polygon in fixture.polygons %}
						var s = new Polygon(
							[ {% for point in polygon %} {% if not forloop.first %}, {% endif %} Vec2.weak({{point.x}},{{point.y}})  {% endfor %} ],
							mat,
							filt
						);
						s.body = body;
						s.fluidEnabled = {{fixture.fluidEnabled}};
						s.fluidProperties = prop;
                        cbtype(s.cbTypes, "{{fixture.cbType}}");
					{% endfor %}
				{% endif %}
			{% endfor %}

			var anchor = if({{body.auto_anchor}}) body.localCOM.copy() else Vec2.get({{body.anchorPointAbs.x}},{{body.anchorPointAbs.y}});
			body.translateShapes(Vec2.weak(-anchor.x,-anchor.y));
			body.position.setxy(0,0);

			bodies.set("{{body.name}}",{body:body,anchor:anchor});
		{% endfor %}
	}
}
