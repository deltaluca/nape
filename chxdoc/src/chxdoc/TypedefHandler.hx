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

class TypedefHandler extends TypeHandler<TypedefCtx> {

	var current : Typedef;

	public function new() {
		super();
	}

	public function pass1(t : Typedef) : TypedefCtx {
		current = t;
		var ctx = newTypedefCtx(t);

		ctx.platforms = t.platforms;

		if( t.platforms.length == 0 ) {
			processTypedefType(ctx, t.type, t.platforms, t.platforms);
		}
		else {
			var platforms = new List();
			for( p in t.platforms )
				platforms.add(p);
			for( p in t.types.keys() ) {
				var td = t.types.get(p);
				var support = new List();
				for( p2 in platforms )
					if( TypeApi.typeEq(td, t.types.get(p2)) ) {
						platforms.remove(p2);
						support.add(p2);
					}
				if( support.length == 0 )
					continue;
				processTypedefType(ctx, td, t.platforms, support);
			}
		}

		var aliases = 0;
		var typedefs = 0;
		for(i in ctx.contexts) {
			switch(i.type) {
			case "alias":
				if(i.platforms.length == 0)
					aliases++;
				else
					aliases += i.platforms.length;
			case "typedef":
				if(i.platforms.length == 0)
					typedefs++;
				else
					typedefs += i.platforms.length;
			default:
				throw "error";
			}
		}
		if(aliases >= typedefs) {
			ctx.type = "alias";
			ctx.isAlias = true;
		} else {
			ctx.type = "typedef";
			ctx.isAlias = false;
		}
		// may have changed from "typedef" to "alias"
		resetMetaKeywords(ctx);

		mergeContexts(ctx);
		return ctx;
	}

	function processTypedefType(origContext : TypedefCtx, t : CType, all : List<String>, platforms : List<String>) {
		var me = this;
		var context = newTypedefCtx(current);

		switch(t) {
		case CAnonymous(fields): // fields == list<{t:CType, name:String}>
			for( f in fields ) {
				var field = createField(context, f.name, false, platforms, "");
				field.returns =  doStringBlock(
						function() {
							me.processType(f.t);
						}
				);
				context.fields.push(field);
			}
			context.type = "typedef";
			context.isAlias = false;
		default:
			context.alias = doStringBlock(
				function() {
					me.processType(t);
				}
			);
			context.type = "alias";
			context.isAlias = true;
		}

		if( platforms.length == ChxDocMain.config.platforms.length) {
			context.isAllPlatforms = true;
			context.platforms = ChxDocMain.config.platforms;
		} else {
			context.isAllPlatforms = false;
			context.platforms = platforms;
		}

		if(context.type == "typedef") {
			context.fields.sort(TypeHandler.ctxFieldSorter);
		}

		context.parent = origContext;
		origContext.contexts.push(context);
	}


	/**
		<pre>Types -> create documentation</pre>
	**/
	public function pass2(pkg : PackageContext, ctx : TypedefCtx) {
		if(ctx.originalDoc != null)
			ctx.docs = DocProcessor.process(pkg, ctx, ctx.originalDoc);
		else
			ctx.docs = null;
	}

	/**
		<pre>Types	-> Resolve all super classes, inheritance, subclasses</pre>
	**/
	public function pass3(pkg : PackageContext, context : TypedefCtx) {
	}

	public function newTypedefCtx(t : Typedef) : TypedefCtx {
		var c = createCommon(t, "typedef");
		Reflect.setField(c, "isAlias", false);
		Reflect.setField(c, "alias",null);
		Reflect.setField(c, "fields", new Array<FieldCtx>());
		return cast c;
	}

	function mergeContexts(ctx : TypedefCtx) {
		var newCtxs = new Array<TypedefCtx>();
		for(ce in ctx.contexts) {
			var current : TypedefCtx = cast ce;
			if(current.type == "alias") {
				var found = false;
				for(e in newCtxs) {
					if(e.alias == current.alias) {
						for(p in current.platforms)
							e.platforms.add(p);
						found = true;
						break;
					}
				}
				if(!found)
					newCtxs.push(current);
			}
			else {
				var found = false;
				for(e in newCtxs) {
					if(e.type != "typedef")
						continue;
					for(p in current.platforms)
						e.platforms.add(p);
					for(f in current.fields) {
						var foundField : FieldCtx = null;
						for(f2 in e.fields) {
							if(CtxApi.fieldEqual(f, f2)) {
								foundField = f2;
								break;
							}
						}
						if(foundField == null) {
							e.fields.push(f);
						} else {
							for(p in f.platforms)
								foundField.platforms.add(p);
						}
					}
					found = true;
					break;
				}
				if(!found)
					newCtxs.push(current);
			}
		}

		// Sort platforms for each context
		// Sort fields in typedefs
		for(current in newCtxs) {
			current.platforms = Utils.listSorter(current.platforms);
			if(current.type != "alias")
				current.fields.sort(TypeHandler.ctxFieldSorter);
		}

		// Sort all the contexts so aliases come first
		// After that, types with more platforms come first
		newCtxs.sort(
			function(a, b){
				if(a.type == "alias") {
					if(b.type == "typedef")
						return -1;
					if(a.platforms.length > b.platforms.length)
						return -1;
					if(a.platforms.length < b.platforms.length)
						return 1;
					return 0;
				}
				if(b.type == "alias")
					return 1;
				if(a.platforms.length > b.platforms.length)
					return -1;
				if(a.platforms.length < b.platforms.length)
					return 1;
				return 0;
			}
		);
		ctx.contexts = untyped newCtxs;
	}

}