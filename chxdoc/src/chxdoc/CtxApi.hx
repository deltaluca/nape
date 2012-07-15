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

import chxdoc.Types;

class CtxApi {
	/**
		Returns the parent Ctx, ascending to the very top if [top] is [true]
		@param ctx Any Ctx
		@param top Return root anscestor if true
		@returns Parent or null
	**/
	public static function getParent(ctx : Ctx, top : Bool = false) {
		if(!top)
			return ctx.parent;
		var c = ctx;
		if(ctx.type == "field") {
			var f : FieldCtx = cast ctx;
			if(f.isInherited || f.isOverride) {
				c = f.inheritance.owner;
			}
		}
		while(c.parent != null)
			c = c.parent;
		return c;
	}

	/**
		Makes an Anchor tag for a type
		@param ctx Any Ctx
		@return Empty string or "#..."
	**/
	public static function makeAnchor(ctx : Ctx) : String {
		if(ctx == null)
			return "";
		switch(ctx.type) {
		case "class", "alias", "typedef", "enum":
			return "#top";
		case "field":
			var f : FieldCtx = cast ctx;
			var rv = "#" + ctx.name;
			if(f.isMethod)
				rv += "()";
			return rv;
		case "enumfield":
			return "#" + ctx.name + "()";
		}
		trace("Error in makeAnchor for type " + ctx.type + " Please report.");
		return "";
	}

	/**
		Returns true if the two fields provided could be conceptually called 'equal'.
		This does not check the containing context, however, so two fields in
		different contexts could be considered equal.
	**/
	public static function fieldEqual(f1 : FieldCtx, f2 : FieldCtx) {
		return (
				f1.name == f2.name &&
				f1.args == f2.args &&
				f1.returns == f2.returns &&
				f1.isMethod == f2.isMethod &&
				f1.isStatic == f2.isStatic &&
				f1.isDynamic == f2.isDynamic &&
				f1.rights == f2.rights &&
				f1.originalDoc == f2.originalDoc
		);
	}
}