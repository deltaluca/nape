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
import sys.FileSystem;

class Utils {
	static var filters : List<String> = new List<String>();
	static var allowedOnly : List<String> = new List<String>();

	/**
		Takes all items in arr and prefixes them with the
		path and leading period.
		@param arr Package or class names
		@param path Prepended path data
		@return New array of strings
	**/
	public static function prefix( arr : Array<String>, path : String ) : Array<String> {
		var arr = arr.copy();
		for( i in 0...arr.length )
			arr[i] = path + "." + arr[i];
		return arr;
	}

	/**
		Transforms flash9.xxx to flash
	**/
// and any private types, which are
// 		created in subdirectories with a leading underscore,, have
// 		the underscore directory removed.
	public static function normalizeTypeInfosPath(path : String) : String {
		if( path.substr(0,7) == "flash9." )
			return "flash."+path.substr(7);
		return path;
	}

	/**
		Basic string sort function for Array.sort()
		@param a First string
		@param b Second string
		@return 0 if a == b, 1 if a > b, -1 if a < b
	**/
	public static function stringSorter(a : String, b : String) : Int {
		if(a > b) return 1;
		if(a < b) return -1;
		return 0;
	}

	/**
		Sorts an array of TypeTree elements based on full paths
		@param a Array to be sorted in place
	**/
	public static function sortTypeTree(a : Array<TypeTree>) : Void {
		var f = function(a, b) {
			var nameA = extractFullPath(a);
			var nameB = extractFullPath(b);
			return stringSorter(nameA, nameB);
		}
		a.sort(f);
	}

	/**
		Extracts the full path from a TypeTree instnace.
	**/
	public static function extractFullPath(t : TypeTree) : String {
		return switch(t) {
			case TPackage(_, full, _): full;
			case TEnumdecl(t): t.path;
			case TClassdecl(t): t.path;
			case TTypedecl(t): t.path;
		};
	}

	public static function stringFormatTree(list : Array<TypeTree>, indent:String, expandClasses: Bool) : String {
		var s : String = "";
		for( entry in list ) {
			switch(entry) {
			case TPackage(name, full, l):
				s += "\n"+indent+"TPackage " + full + " {" + stringFormatTree(l, indent + "  ", expandClasses);
				s += "\n"+indent+"}";
			case TTypedecl(t):
				s += "\n"+indent+"TTypedecl(" + t.path + ")";
			case TEnumdecl(e):
				s += "\n"+indent+"TEnumdecl(" + e.path + ")";
			case TClassdecl(c):
				if(!expandClasses)
					s += "\n"+indent+"TClassdecl(" + c.path + ")";
				else s += "\n"+indent+Std.string(c);
			}
		}
		return s;
	}

	/**
		Returns a keyword for the access rights of a class var
	**/
	public static function rightsStr(r) : String {
		return switch(r) {
		case RNormal: "default";
		case RNo: "null";
		case RCall(m): m;
		case RMethod: "method";
		case RDynamic: "dynamic";
		case RInline: "inline";
		}
	}

	/**
		Creates a path to an html file relative to the current path.
	**/
	public static function makeRelPath( pathStr : String ) {
		return ChxDocMain.baseRelPath + pathStr  + ChxDocMain.config.htmlFileExtension;
	}

	public static function makeUrl( url, text, cssClass ) {
		return "<a href=\"" + ChxDocMain.baseRelPath + url + ChxDocMain.config.htmlFileExtension + "\" class=\""+cssClass+"\">"+text+"</a>";
	}

	public static function makeTypeBaseRelPath(path : String) {
		var parts = path.split(".");

	}

	/////////////////////////////////////
	//              FILTERS            //
	/////////////////////////////////////
	public static function addFilter(s : String) {
		filters.add(s);
	}

	/**
	* Sets a package or class name that may be allowed,
	* filtering everything else
	*
	* @param s Class path (ie. mypackage.* or mypackage.MyClass)
	*/
	public static function addAllowOnly(s:String) : Void {
		if(s==null || s.length == 0) return;
		if(s.charAt(s.length-1) == "*")
			s = s.substr(0, s.length-1);
		if(s.indexOf(".") < 0) // a root type
		{
			allowedOnly.remove("root types.");
			allowedOnly.add("root types.");
		}
		allowedOnly.add(s);
	}

	/**
	* Checks if a package or class is filtered
	**/
	public static function isFiltered( path : Path, isPackage : Bool ) {
		if( isPackage && path == "Remoting" )
			return true;
		if( StringTools.endsWith(path,"__") )
			return true;
		for( x in filters )
			if( StringTools.startsWith(path,x) )
				return true;
		var ao = false;
		if(isPackage)
			path += ".";
		for( x in allowedOnly ) {
			ao = true;
			if( x.charAt(x.length-1) == "." ) {
				if( StringTools.startsWith(path,x) )
					return false;
			}
			if( path == x ) {
				return false;
			}
		}
		// if there were any allowedOnly entries, anything
		// else is filtered.
		if(ao) return true;

		return false;
	}

	public static function writeFileContents(filePath:String, contents: String) {
		var fp = neko.io.File.write(filePath, true);
		fp.writeString(contents);
		fp.flush();
		fp.close();
	}

	public static function addSubdirTrailingSlash(dir : String) {
		if(dir.length > 0)
			if(dir != "/" && dir.charAt(dir.length -1) != "/")
				return dir + "/";
		return dir;
	}

	public static function makeRelativeSubdirLink(ctx : Ctx) {
		var parts = ctx.path.split(".");
		parts.pop();
		return addSubdirTrailingSlash(parts.join("/"));
	}

	public static function makeRelativePackageLink(context : PackageContext) {
		var parts = context.full.split(".");
		return addSubdirTrailingSlash(parts.join("/"));
	}

	/**
		Tries to create an output directory, making all parent directories.
		@todo Windows does not work correctly with [exists] and [createDirectory], so a wrapper in chx should consider this
	**/
	public static function createOutputDirectory(path:String) {
		if(path == null)
			throw "Output directory is null";
		// trim off the trailing slash for windows
		if(path != "/" && path != "\\") {
			var s = path.charAt(path.length-1);
			if(s == "/" || s == "\\")
				path = path.substr(0, path.length-1);
			ensureDirectory(path);
		}
	}

	private static function ensureDirectory(dir : String) {
		try {
			if(!FileSystem.exists(dir))
				FileSystem.createDirectory(dir);
		} catch( e : Dynamic) {
			ensureDirectory(neko.io.Path.directory(dir));
			FileSystem.createDirectory(dir);
		}
		if(!FileSystem.isDirectory(dir))
			throw "Output path " + dir + " is not a directory.";
	}

	/**
	* Translates html special characters for links etc.
	* <ul>
    * <li>'&amp;' (ampersand) becomes '&amp;amp;'</li>
    * <li>'&quot' (double quote) becomes '&amp;quot;' (if doQuotes is true)</li>
    * <li>'&lt;' (less than) becomes '&amp;lt;'</li>
    * <li>'&gt;' (greater than) becomes '&amp;gt;'</li>
	* </ul>
	* @returns reformatted string
	*/
	public static function htmlSpecialChars(s : String, doQuotes : Bool = false) : String {
		#if neko
			s = ~/&/g.replace(s, "&amp;");
			s = ~/</g.replace(s, "&lt;");
			s = ~/>/g.replace(s, "&gt;");
			if(doQuotes) {
				s = ~/"/g.replace(s, "&quot;");
			}
		#else
			s = StringTools.replace(s, "&", "&amp;");
			s = StringTools.replace(s, "&amp;amp;", "&amp;");
			s = StringTools.replace(s, "<", "&lt;");
			s = StringTools.replace(s, ">", "&gt;");
			if(doQuotes) {
				s = StringTools.replace(s, "\"", "&quot;");
			}
		#end
		return s;
	}

	/**
		Makes an html encoded Link
	**/
	public static function makeLink(href : String, text : String, css:String) : Link {
		if(href == null) href = "";
		if(text == null) text = "";
		if(css == null) css = "";
		return {
			href	: htmlSpecialChars(href, true),
			text	: htmlSpecialChars(text, true),
			css		: htmlSpecialChars(css, true),
		};
	}

	/**
		Sorts a string list.
	**/
	public static function listSorter(list : List<String>) : List<String> {
		var a = new Array();
		for(p in list)
			a.push(p);
		a.sort(stringSorter);
		var nl = new List<String>();
		for(p in a)
			nl.add(p);
		return nl;
	}
}
