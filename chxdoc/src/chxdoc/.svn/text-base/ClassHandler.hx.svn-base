/*
 * Copyright (c) 2008-2009, The Caffeine-hx project contributors
 * Original author : Russell Weir
 * Contributors:
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE CAFFEINE-HX PROJECT CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE CAFFEINE-HX PROJECT CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

package chxdoc;

import haxe.rtti.CType;
import chxdoc.Defines;
import chxdoc.Types;

class ClassHandler extends TypeHandler<ClassCtx> {
	public function new() {
		super();
	}

	public function pass1(c : Classdef) : ClassCtx {
		return newClassCtx(c);
	}


	public function pass2(pkg : PackageContext, ctx : ClassCtx) {
		ctx.docs = DocProcessor.process(pkg, ctx, ctx.originalDoc);

		if(ctx.constructor != null)
			ctx.constructor.docs = DocProcessor.process(pkg, ctx.constructor, ctx.constructor.originalDoc);
		var me = this;

		forAllFields(ctx,
			function(f:FieldCtx) {
				f.docs = DocProcessor.process(pkg, f, f.originalDoc);
				if(f.docs != null) {
					if (f.docs.forcePrivate) {
						if(f.isMethod && ChxDocMain.config.showPrivateMethods)
							f.docs.forcePrivate = false;
						else if (!f.isMethod && ChxDocMain.config.showPrivateVars)
							f.docs.forcePrivate = false;
						if (f.docs.forcePrivate)
							f.isPrivate = true;
					}

				}
			}
		);
	}

	//Types	-> Resolve all super classes, inheritance, subclasses
	public function pass3(pkg : PackageContext, ctx : ClassCtx) {
		var allInterfaces : Hash<Bool> = new Hash();
		// resolve interfaces
		for(ipp in ctx.interfacesPaths) {
			allInterfaces.set(ipp.path, true);
		}

		// resolve superClass
		var sc : PathParams = ctx.scPathParams;
		var first = true;
		while(sc != null) {
			var s : Ctx = ChxDocMain.findType(sc.path);
			var source : ClassCtx = cast s;
			ChxDocMain.logDebug("Pass3", pkg, ctx);
			// add to superClasses
			ctx.superClasses.unshift(source);
			if(first) {
				// on first pass, the superclass has this class ctx
				// added as a subclass
				first = false;
				addSubclass(source, ctx);
			}
			// add all vars in current superclass to class ctx
			for(i in source.vars)
				makeInheritedVar(ctx, source, i);
			// add all methods in current superclass to class ctx
			for(i in source.methods)
				makeInheritedMethod(ctx, source, i);
			// add all interfaces in current superclass to class ctx
			for(i in source.interfacesPaths)
				allInterfaces.set(i.path, true);
			// walk up to next superclass
			sc = source.scPathParams;
		}

		for(path in allInterfaces.keys()) {
			var s : Ctx = ChxDocMain.findType(path);
			var source : ClassCtx = cast s;
			#if debug
			if(source == null)
				throw "CHXDOC Assert error";
			#end
			ctx.interfaces.push(source);
		}

		// check each field for inheritance
		for(f in ctx.methods) {
			if(f.isOverride) {
				var ctx2 = getMethodOriginator(ctx, f.name);
				if(ctx2 != null) {
					//trace("In " + ctx.nameDots + " method "+ f.name + " originated in " + ctx2.nameDots);
					f.inheritance.owner = ctx2;
					makeInheritedFieldLink(ctx, f);
				}
			}
		}

		// mark all @private inheritors
		var a : Array<Array<FieldCtx>> = [ctx.vars, ctx.staticVars, ctx.methods, ctx.staticMethods];
		// private vars and methods need to be removed
		var trimFields = new Array<FieldCtx>();
		for(fa in a) {
			for(f in fa) {
				if(f.isMethod && !ChxDocMain.config.showPrivateMethods && getIsPrivate(ctx, f.name)) {
					f.isPrivate = true;
				}
				if (!f.isMethod && !ChxDocMain.config.showPrivateVars && getIsPrivate(ctx, f.name)) {
					f.isPrivate = true;
				}
			}
		}
	}

	/**
	 * Remove all private methods before output
	 **/
	public function pass4(pkg : PackageContext, ctx : ClassCtx) {
		var a : Array<Array<FieldCtx>> = [ctx.vars, ctx.staticVars, ctx.methods, ctx.staticMethods];
		// private vars and methods need to be removed
		var trimFields = new Array<FieldCtx>();
		for(fa in a) {
			for(f in fa) {
				if(f.isMethod && !ChxDocMain.config.showPrivateMethods && getIsPrivate(ctx, f.name))
					trimFields.push (f);
				if (!f.isMethod && !ChxDocMain.config.showPrivateVars && getIsPrivate(ctx, f.name))
					trimFields.push (f);
			}
		}
		for (field in trimFields) {
			if(field.isMethod) {
				ctx.methods.remove (field);
				ctx.staticMethods.remove (field);
			} else {
				ctx.vars.remove (field);
				ctx.staticVars.remove (field);
			}
		}

		// and all sorted
		for(fa in a)
			fa.sort(TypeHandler.ctxFieldSorter);
	}

	/**
	 * Return the named method from a ClassCtx. This function checks only the
	 * non-static methods.
	 * @return FieldCtx or null
	 **/
	static function getMethod(ctx: ClassCtx, name : String) : FieldCtx {
		for(i in ctx.methods)
			if(i.name == name)
				return i;
		return null;
	}

	/**
	 * Returns the named field from the class, regardless of what type the field is
	 * @return FieldCtx or null
	 **/
	static function getField(ctx : ClassCtx, name : String) : FieldCtx {
		var atypes : Array<Array<FieldCtx>> = [ctx.methods, ctx.vars, ctx.staticMethods, ctx.staticVars];
		for(a in atypes) {
			for(i in a) 
				if(i.name == name)
					return i;
		}
		return null;
	}

	/**
	 * Crawls up the inheritance tree to find if a field is private. Any superclass that
	 * has flagged the field as private will cause this to return 'true'.
	 **/
	static function getIsPrivate(ctx : ClassCtx, name :String) : Bool {
		while(ctx != null) {
			var f : FieldCtx = getField(ctx, name);
			if(f != null && f.isPrivate)
				return true;
			// check interfaces
			for(i in ctx.interfaces)
				if(getIsPrivate(i, name))
					return true;
			// go to superClass
			var sc = ctx.scPathParams;
			if(sc == null)
				break;
			ctx = cast ChxDocMain.findType(sc.path);
		}
		return false;
	}

	/**
	 * Gets the first superclass that contains a definition for a method.
	 * @param ctx a class where the superclass will be the first to be checked
	 * @param name A method name
	 */
	static function getMethodOriginator(ctx : ClassCtx, name:String) : ClassCtx {
		var rv : ClassCtx = null;
		var sc = ctx.scPathParams;
		while(sc != null && rv == null) {
			ctx = cast ChxDocMain.findType(sc.path);
			var f : FieldCtx = getMethod(ctx, name);
			if(f != null) {
				if((!f.isInherited && f.isOverride) || (!f.isInherited && !f.isOverride)) {
					rv = ctx;
				}
			} else {
			}
			sc = ctx.scPathParams;
		}
		return rv;
	}

	function addSubclass(superClass : ClassCtx, subClass : ClassCtx) : Void {
		var link = makeBaseRelPath(superClass) +
			subClass.subdir +
			subClass.name +
			ChxDocMain.config.htmlFileExtension;
		superClass.subclasses.push({
			text : subClass.nameDots,
			href : link,
			css : "subclass",
		});
	}

	/**
		Creates and returns a new field based on an existing super class field.
		@param ownerCtx The super class Ctx which owns [field]
		@param field The method or var being inherited or overridden
	**/
	function createInheritedField(ownerCtx:ClassCtx, field : FieldCtx) : FieldCtx {
		var f = createField(
			ownerCtx,
			field.name,
			field.isPrivate,
			field.platforms,
			field.originalDoc);

		f.params = field.params;
		f.docs = field.docs;

		f.args = field.args;
		f.returns = field.returns;
		f.isMethod = field.isMethod;
		f.isInherited = true;
		f.isOverride = false;
		f.isInline = field.isInline;
		f.inheritance = {
			owner : ownerCtx,
			link :
				{
					text: null,
					href: null,
					css : null,
				},
		};
		f.isStatic = field.isStatic;
		f.isDynamic = field.isDynamic;
		f.rights = field.rights;

		return f;
	}

	/**
		Recreates the link for field inheritance.
		@param ctx The class that [field] belongs to
		@param field A field with [inheritance.owner] set
		@throws String if inheritance or inheritance.owner is null
	**/
	function makeInheritedFieldLink(ctx : ClassCtx, field : FieldCtx) : Void {
		if(field.inheritance == null || field.inheritance.owner == null)
			throw "Error creating inheritance field link for " + field;

		field.inheritance.link = Utils.makeLink(
			makeBaseRelPath(ctx) +
				field.inheritance.owner.subdir +
				field.inheritance.owner.name +
				ChxDocMain.config.htmlFileExtension,
			field.inheritance.owner.nameDots,
			"inherited"
		);
	}

	/**
		Creates an inherited var field and attaches it to the supplied ClassCtx.
		@param ctx The class receiving a new field.
		@param srcCtx The super class that owns [field]
		@param field The field to be copied
	**/
	function makeInheritedVar(ctx : ClassCtx, srcCtx:ClassCtx, field : FieldCtx) {
		var f : FieldCtx =
			if(!field.isInherited)
				createInheritedField(srcCtx, field)
			else
				createInheritedField(field.inheritance.owner, field);

		makeInheritedFieldLink(ctx, f);
		for(v in ctx.vars)
			if(v.name == f.name) return;
		ctx.vars.push(f);
	}

	function makeInheritedMethod(ctx : ClassCtx, srcCtx:ClassCtx, field : FieldCtx) {
		var cur = getMethod(ctx, field.name);
		if(cur != null && (cur.isInherited || cur.isOverride)) {
			ChxDocMain.logDebug(cur.name + (cur.isInherited?" is inherited":"") + (cur.isOverride?" is an override":""));
			return;
		}

		ChxDocMain.logDebug("Creating inherited method " + field.name);
		var f = createInheritedField(srcCtx, field);
		if(cur != null) {
			f.isInherited = false;
			f.isOverride = true;
		}
		if(!field.isInherited) {
			f.inheritance.owner = srcCtx;
		}
		else {
			var f2 = getMethod(srcCtx, field.name);
			while(!f2.isInherited)
				f2 = getMethod(f2.inheritance.owner, field.name);
			f.inheritance.owner = f2.inheritance.owner;
		}

		makeInheritedFieldLink(ctx, f);
		ctx.methods.push(f);
	}

	function newClassCtx(c : Classdef) : ClassCtx {
		var ctx : ClassCtx = null;
		var me = this;

		if( c.isInterface )
			ctx = cast createCommon(c, "interface");
		else
			ctx = cast createCommon(c, "class");

		Reflect.setField(ctx, "scPathParams", c.superClass);
		Reflect.setField(ctx, "superClassHtml", null);
		Reflect.setField(ctx, "superClasses", new Array<ClassCtx>());
		Reflect.setField(ctx, "interfacesPaths", new Array<PathParams>());
		Reflect.setField(ctx, "interfacesHtml", new Array<Html>());
		Reflect.setField(ctx, "interfaces", new Array<ClassCtx>());
		Reflect.setField(ctx, "isDynamic", (c.tdynamic != null));
		Reflect.setField(ctx, "constructor", null);
		Reflect.setField(ctx, "vars", new Array<FieldCtx>());
		Reflect.setField(ctx, "staticVars", new Array<FieldCtx>());
		Reflect.setField(ctx, "methods", new Array<FieldCtx>());
		Reflect.setField(ctx, "staticMethods", new Array<FieldCtx>());
		Reflect.setField(ctx, "subclasses", new Array<Link>());

		if( c.superClass != null ) {
			ctx.superClassHtml = doStringBlock(
				function() {
					me.processPath(c.superClass.path, c.superClass.params);
				}
			);
		}

		if(!c.interfaces.isEmpty()) {
			for(i in c.interfaces) {
				ctx.interfacesPaths.push(i);
				ctx.interfacesHtml.push(
					doStringBlock(
						function() {
							me.processPath(i.path, i.params);
						}
					)
				);
			}
		}

		if(c.tdynamic != null) {
			ctx.interfacesHtml.push(
				"<A HREF=\"http://haxe.org/ref/dynamic#Implementing Dynamic\" TARGET=\"#new\">Dynamic</A>"
			);
		}

		for( f in c.fields ) {
			var field = newClassFieldCtx(ctx, f, false);
			if(field != null) {
				if(field.name == "new" && !c.isInterface) {
					ctx.constructor = field;
				} else {
					if(field.isMethod)
						ctx.methods.push(field);
					else
						ctx.vars.push(field);
				}
			}
		}

		for( f in c.statics ) {
			var field = newClassFieldCtx(ctx, f, true);
			if(field != null) {
				if(field.isMethod)
					ctx.staticMethods.push(field);
				else
					ctx.staticVars.push(field);
			}
		}

		return ctx;
	}


	function newClassFieldCtx(c : ClassCtx, f : ClassField, isStatic : Bool) : FieldCtx
	{
		var me = this;
		var ctx : FieldCtx = createField(c, f.name, !f.isPublic, f.platforms, f.doc);
		ctx.isStatic = isStatic;
		ctx.isOverride = f.isOverride;

		var oldParams = TypeHandler.typeParams;
		if( f.params != null )
			TypeHandler.typeParams = TypeHandler.typeParams.concat(Utils.prefix(f.params,f.name));

		switch( f.type ) {
		case CFunction(args,ret):
			//trace("Examining method " + f.name + " in " + c.nameDots + " f.get: " + Std.string(f.get) + " f.set: " + Std.string(f.set));
			// sqrt in Math f.get: RNormal f.set: RMethod (Standard methods)
			// new in chx.sys.C f.get: RNormal f.set: RMethod 
			// dynamicMethod in chx.sys.Layer1 f.get: RNormal f.set: RDynamic
			// method onerror in js.Lib f.get: RNormal f.set: RNormal (which is a static var)
			//      static var onerror : String -> Array<String> -> Bool = null
			//
			// Normal methods: ( f.get == RNormal && f.set == RMethod )
			// Inline methods: ( f.get == RInline && f.set = RNo )
			// Dynamic methods: ( f.get == RNormal && f.set = RDynamic )
			// Variables (f.get == RNormal && f.set == RNormal )
			
			//if( f.get == RNormal && (f.set == RNormal || f.set == RDynamic) ) {
			if( f.set != RNormal ) {
				//trace("is a method");
				ctx.isMethod = true;

				if( f.get == RInline )
					ctx.isInline = true;

				if( f.set == RDynamic )
					ctx.isDynamic = true;

				if( f.params != null )
					ctx.params = "<"+f.params.join(", ")+">";

				ctx.args = doStringBlock( function() {
					me.display(args,function(a) {
						if( a.opt )
							me.write("?");
						if( a.name != null && a.name != "" ) {
							me.write(a.name);
							me.write(" : ");
						}
						me.processType(a.t);
					},", ");
				});

				ctx.returns = doStringBlock(
					function() {
						me.processType(ret);
					}
				);
			}
		default:
		}
		if(!ctx.isMethod) {
			if( f.get != RNormal || f.set != RNormal )
				ctx.rights = ("("+Utils.rightsStr(f.get)+","+Utils.rightsStr(f.set)+")");

			ctx.returns = doStringBlock(
				function() {
					me.processType(f.type);
				}
			);
		}

		/*
		if( !f.isPublic ) {
			if(ctx.isMethod && !ChxDocMain.config.showPrivateMethods)
				return null;
			if(!ctx.isMethod && !ChxDocMain.config.showPrivateVars)
				return null;
		}
		*/

		if( f.params != null )
			TypeHandler.typeParams = oldParams;
		return ctx;
	}

	/**
		Applies a function to all fields (vars and methods both static and member) in a class context.
		@param ctx A class context
		@param f Function taking a FieldCtx returning Void
	**/
	function forAllFields(ctx : ClassCtx, f : FieldCtx->Void) {
		var a = [ctx.vars, ctx.staticVars, ctx.methods, ctx.staticMethods];
		for(e in a)
			for(i in e)
				f(i);
	}
}
