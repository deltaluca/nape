package;

import nape.phys.Body;
import nape.phys.BodyType;
import nape.shape.Shape;
import nape.shape.Polygon;
import nape.shape.Circle;
import nape.geom.Vec2;
import nape.geom.Vec3;
import nape.dynamics.InteractionFilter;
import nape.phys.Material;
import nape.phys.FluidProperties;
import nape.callbacks.CbType;
import nape.callbacks.CbTypeList;
import nape.geom.AABB;

import flash.display.DisplayObject;

import StringTools;

class PhysicsData {

    /**
     * Get position and rotation for graphics placement.
     *
     * Example usage:
     * <code>
     *    space.step(1/60);
     *    space.liveBodies.foreach(updateGraphics);
     *    ...
     *    function updateGraphics(body:Body):Void {
     *       var position:Vec3 = PhysicsData.graphicsPosition(body);
     *       var graphic:DisplayObject = body.userData.graphic;
     *       graphic.x = position.x;
     *       graphic.y = position.y;
     *       graphic.rotation = position.z;
     *       position.dispose(); //release to object pool.
     *    }
     * </code>
     * In the case that you are using a flash DisplayObject you can simply
     * use <code>space.liveBodies.foreach(PhysicsData.flashGraphicsUpdate);</code>
     * but if using, let's say Starling or NME you should write the equivalent version
     * of the example above.
     *
     * @param body The Body to get graphical position/rotation of.
     * @return A Vec3 allocated from object pool whose x/y are the position
     *         for graphic, and z the rotation in degrees.
     */
    public static function graphicsPosition(body:Body):Vec3 {
        var pos = body.localPointToWorld(cast body.userData.graphicOffset);
        var ret = Vec3.get(pos.x, pos.y, (body.rotation * 180/Math.PI) % 360);
        pos.dispose();
        return ret;
    }

    /**
     * Method to update a flash DisplayObject assigned to a Body
     *
     * @param body The Body having a flash DisplayObject to update graphic of.
     */
    public static function flashGraphicsUpdate(body:Body):Void {
        var position:Vec3 = PhysicsData.graphicsPosition(body);
        var graphic:DisplayObject = body.userData.graphic;
        graphic.x = position.x;
        graphic.y = position.y;
        graphic.rotation = position.z;
        position.dispose(); //release to object pool.
    }

    /**
     * Method to create a Body from the PhysicsEditor exported data.
     *
     * If supplying a graphic (of any type), then this will be stored
     * in body.userData.graphic and an associated body.userData.graphicOffset
     * Vec2 will be assigned that represents the local offset to apply to
     * the graphics position.
     *
     * @param name The name of the Body from the PhysicsEditor exported data.
     * @param graphic (optional) A graphic to assign and find a local offset for.
                      This can be of any type, but should have a getBounds function
                      that works like that of the flash DisplayObject to correctly
                      determine a graphicOffset.
     * @return The constructed Body.
     */
    public static function createBody(name:String,?graphic:DisplayObject):Body {
        var xret = lookup(name);
        if(graphic==null) return xret.body.copy();

        var ret = xret.body.copy();
        graphic.x = graphic.y = 0;
        graphic.rotation = 0;
        var bounds = graphic.getBounds(graphic);
        var offset = Vec2.get(bounds.x-xret.anchor.x, bounds.y-xret.anchor.y);

        ret.userData.graphic = graphic;
        ret.userData.graphicOffset = offset;

        return ret;
    }

    /**
     * Register a Material object with the name used in the PhysicsEditor data.
     *
     * @param name The name of the Material in the PhysicsEditor data.
     * @param material The Material object to be assigned to this name.
     */
    public static function registerMaterial(name:String,material:Material) {
        if(materials==null) materials = new Hash<Material>();
        materials.set(name,material);
    }

    /**
     * Register a InteractionFilter object with the name used in the PhysicsEditor data.
     *
     * @param name The name of the InteractionFilter in the PhysicsEditor data.
     * @param filter The InteractionFilter object to be assigned to this name.
     */
    public static function registerFilter(name:String,filter:InteractionFilter) {
        if(filters==null) filters = new Hash<InteractionFilter>();
        filters.set(name,filter);
    }

    /**
     * Register a FluidProperties object with the name used in the PhysicsEditor data.
     *
     * @param name The name of the FluidProperties in the PhysicsEditor data.
     * @param properties The FluidProperties object to be assigned to this name.
     */
    public static function registerFluidProperties(name:String,properties:FluidProperties) {
        if(fprops==null) fprops = new Hash<FluidProperties>();
        fprops.set(name,properties);
    }

    /**
     * Register a CbType object with the name used in the PhysicsEditor data.
     *
     * @param name The name of the CbType in the PhysicsEditor data.
     * @param cbType The CbType object to be assigned to this name.
     */
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
                    s.sensorEnabled = {{fixture.sensorEnabled}};
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
                        s.sensorEnabled = {{fixture.sensorEnabled}};
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
