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

class TypeHandler<T> {
	static var typeParams	: TypeParams = new Array();

	var config				: Config;
	var print				: Dynamic -> Void;
	var println 			: Dynamic -> Void;

	public function new() {
		this.config = ChxDocMain.config;
		if(config.verbose) {
			this.println = ChxDocMain.println;
			this.print = ChxDocMain.print;
		} else {
			this.println = nullPrinter;
			this.print = nullPrinter;
		}
	}

	function nullPrinter(v : Dynamic) : Void {
	}

	public dynamic function output(str) {
		neko.Lib.print(str);
	}

	public function write(str, ?params : Dynamic ) {
		if( params != null )
			for( f in Reflect.fields(params) )
				str = StringTools.replace(str, "$"+f, Std.string(Reflect.field(params, f)));
		output(str);
	}

	function doStringBlock(f : Void-> Void) : String {
		var oo = this.output;
		var s = new StringBuf();
		this.output = s.add;
		f();
		this.output = oo;
		return s.toString();
	}

	/**
		Creates a new metaData entry, with one empty entry in keywords
	**/
	public static function newMetaData() {
		var metaData = {
			date : ChxDocMain.config.dateShort,
			keywords : new Array<String>(),
			stylesheet : ChxDocMain.baseRelPath + "../" + ChxDocMain.config.stylesheet,
		};
		metaData.keywords.push("");
		return metaData;
	}

	function processType( t : CType ) {
		switch( t ) {
		case CUnknown:
			write("Unknown");
		case CEnum(path,params):
			processPath(path,params);
		case CClass(path,params):
			processPath(path,params);
		case CTypedef(path,params):
			processPath(path,params);
		case CFunction(args,ret):
			if( args.isEmpty() ) {
				processPath("Void");
				write(" -> ");
			}
			for( a in args ) {
				if( a.opt )
					write("?");
				if( a.name != null && a.name != "" )
					write(a.name+" : ");
				processTypeFun(a.t,true);
				write(" -> ");
			}
			processTypeFun(ret,false);
		case CAnonymous(fields):
			write("{ ");
			var me = this;
			display(fields,function(f) {
				me.write(f.name+" : ");
				me.processType(f.t);
			},", ");
			write("}");
		case CDynamic(t):
			if( t == null )
				processPath("Dynamic");
			else {
				var l = new List();
				l.add(t);
				processPath("Dynamic",l);
			}
		}
	}

	function processTypeFun( t : CType, isArg ) {
		var parent =  switch( t ) {
			case CFunction(_,_): true;
			case CEnum(n,_): isArg && n == "Void";
			default : false;
		};
		if( parent )
			write("(");
		processType(t);
		if( parent )
			write(")");
	}

	function display<T>( l : List<T>, f : T -> Void, sep : String ) {
		var first = true;
		for( x in l ) {
			if( first )
				first = false;
			else
				write(sep);
			f(x);
		}
	}

	function processPath( path : Path, ?params : List<CType> ) {
		write(makePathUrl(path,"type"));
		if( params != null && !params.isEmpty() ) {
			write("&lt;");
			var first = true;
			for( t in params ) {
				if(first) first = false;
				else write(", ");
				processType(t);
			}
			write("&gt;");
		}
	}

	function makePathUrl( path : Path, css ) {
		if(Utils.isFiltered(path, false))
			return path;
		var p = path.split(".");
		var name = p.pop();
		var local = (p.join(".") == ChxDocMain.currentPackageDots);
		for( x in typeParams )
			if( x == path )
				return name;
		p.push(name);
		if( local )
			return Utils.makeUrl(p.join("/"),name,css);
		return Utils.makeUrl(p.join("/"), Utils.normalizeTypeInfosPath(path),css);
	}

	/**
		Makes a FileInfo structure from a TypeInfos structure. Used
		for Types, not Packages.
	**/
	function makeFileInfo( info : TypeInfos) : FileInfo {
		// with flash9
		var path = info.path;

		// with flash only
		var normalized =  Utils.normalizeTypeInfosPath(path).split(".");
		var nameDots = normalized.join(".");
		var relative = "";
		for(i in 1...normalized.length)
			relative += "../";
		var name = normalized.pop();
		var packageDots = normalized.join(".");
		var parts = path.split(".");
		parts.pop();
		return {
			name 		: name,
			nameDots	: nameDots,
			packageDots : packageDots,
			subdir		: Utils.addSubdirTrailingSlash(parts.join("/")),
			rootRelative: relative,
		}
	}

	/**
		Makes the base relative path from a context.
	**/
	function makeBaseRelPath(ctx : Ctx) {
		var parts = ctx.path.split(".");
		parts.pop();
		var s = "";
		for(i in 0...parts.length)
			s += "../";
		return s;
	}

	/**
		Creates and populates common fields in a Ctx.
		@return New Ctx instance
	**/
	function createCommon(t : TypeInfos, type : String) : Ctx {
		var fi = makeFileInfo(t);
		var c : Ctx = {
			type	: type,

			name			: fi.name,
			nameDots		: fi.nameDots,
			path			: t.path,
			packageDots		: fi.packageDots,
			subdir			: fi.subdir,
			rootRelative	: fi.rootRelative,

			isAllPlatforms	: (t.platforms.length == ChxDocMain.config.platforms.length),
			platforms		: t.platforms,
			parent			: null,
			contexts		: new Array(),

			params			: "",
			module			: t.module,
			isPrivate		: t.isPrivate,
			access			: (t.isPrivate ? "private" : "public"),
			docs			: null,

			meta			: newMetaData(),
			originalDoc		: t.doc,
		}

		if( t.params != null && t.params.length > 0 )
			c.params = "<"+t.params.join(", ")+">";

		if(c.platforms.length == 0) {
			c.platforms = ChxDocMain.config.platforms;
			c.isAllPlatforms = true;
		}

		resetMetaKeywords(c);

		Reflect.setField(c, "__serializeHash", callback(serializeHash, c));
		return c;
	}

	function createField(parentCtx : Ctx, name : String, isPrivate : Bool, platforms : List<String>, originalDoc : String) : FieldCtx {
		var c : FieldCtx = {
			type			: "field",

			name			: name,
			nameDots		: null,
			path			: null,
			packageDots		: null,
			subdir			: null,
			rootRelative	: null,

			isAllPlatforms	: (platforms.length == ChxDocMain.config.platforms.length),
			platforms		: platforms,
			parent			: parentCtx,
			contexts		: null,

			params			: "",
			module			: null,
			isPrivate		: isPrivate,
			access			: (isPrivate ? "private" : "public"),
			docs			: null,

			meta			: null,

			originalDoc		: originalDoc,

			args			: "",
			returns			: "",
			isMethod		: false,
			isInherited		: false,
			isOverride		: false,
			isInline		: false,
			inheritance		: { owner :null, link : null },
			isStatic		: false,
			isDynamic		: false,
			rights			: "",
		}

		if(c.platforms.length == 0) {
			c.platforms = ChxDocMain.config.platforms;
			c.isAllPlatforms = true;
		}

		Reflect.setField(c, "__serializeHash", callback(serializeHash, c));
		return c;
	}

	/**
		Sets the default meta keywords for a context
	**/
	function resetMetaKeywords(ctx : Ctx) : Void {
		ctx.meta.keywords[0] = ctx.nameDots + " " + ctx.type;
	}

	/**
		Set a field in the supplied Ctx instance. This method is added as a callback in
		Ctx instances created with createCommon as the method [setField].
	**/
	function setField(c : Ctx, field : String, value : Dynamic) {
		Reflect.setField(c, field, value);
	}

	static function serializeHash(c : Ctx) : String {
		var s = c.type + c.name;
		if(c.parent != null)
			s += c.parent.type + c.parent.path;
		else
			s += c.nameDots + c.path;
		//Reflect.setField(c, "__serializeHash", new String(s));
		return s;
	}

	/**
		Clones a context, but does not copy the contexts or platforms fields.
		@return Ctx copy
	**/
	function cloneContext(v : Ctx) : Ctx {
		var c = {};
		var c = Reflect.copy(v);
		setField(c, "setField", callback(setField, c));
		c.contexts = new Array();
		c.platforms = new List();
		return c;
	}

	/**
		Copies a list.
		@return new List of type T, empty if [v] is null
	**/
	function cloneList<T>( v : List<T>) : List<T> {
		var rv = new List<T>();
		if(v != null)
			for(i in v)
				rv.add(i);
		return rv;
	}

	public static function ctxSorter(a : Ctx, b : Ctx) : Int {
		return Utils.stringSorter(a.path, b.path);
	}

	public static function ctxFieldSorter(a : FieldCtx, b : FieldCtx) : Int {
		return Utils.stringSorter(a.name, b.name);
	}

	/**
		Takes any Ctx and returns the template output
	**/
	public static function execTemplate(ctx : Ctx) : String  {
		var type = switch(ctx.type) {
		case "typedef", "alias": "typedef";
		case "class", "interface": "class";
		case "enum": "enum";
		default:
			throw ChxDocMain.fatal("Could not determing template type for " + ctx.type);
		}
// 		Reflect.setField(ctx, "meta", TypeHandler.newMetaData());
		Reflect.setField(ctx, "build", ChxDocMain.buildData );
		Reflect.setField(ctx, "config", ChxDocMain.config );
		var t = new mtwin.templo.Loader(type + ".mtt");
		try {
			var rv = t.execute(ctx);
			return rv;
		} catch(e : Dynamic) {
			trace("ERROR generating doc for " + ctx.path + ". Check "+type+".mtt");
			return neko.Lib.rethrow(e);
		}
	}
}