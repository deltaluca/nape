/*
 * Copyright (c) 2008-2009, The Caffeine-hx project contributors
 * Original author : Russell Weir
 * Contributors: Niel Drummond
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

/** Output as raw **/
typedef Html = String;

/** a dotted class path **/
typedef DotPath = String; // a.b.c

/**
	Links include the html escaped text and href, as well as the css type.
**/
typedef Link = {
	var href		: Html;
	var text		: Html;
	var css			: String;
};

typedef Config = {
	var versionMajor		: Int;
	var versionMinor		: Int;
	var versionRevision		: Int;
	var buildNumber			: Int;
	var verbose				: Bool;
	var rootTypesPackage	: PackageContext;
	var allPackages			: Array<PackageContext>;
	var allTypes			: Array<Ctx>;
	var docBuildDate		: Date;
	var dateShort			: String; // YYYY-MM-DD
	var dateLong			: String; // Web Feb 12 HH:MM:SS GMT 2008
	var showAuthorTags		: Bool;
	var showPrivateClasses	: Bool;
	var showPrivateTypedefs	: Bool;
	var showPrivateEnums	: Bool;
	var showPrivateMethods	: Bool;
	var showPrivateVars		: Bool;
	var showTodoTags		: Bool;
	var temploBaseDir		: String; // path
	var temploTmpDir		: String; // path
	var temploMacros		: String; // macros.mtt
	var htmlFileExtension	: String; // .html
	/** the stylesheet name, relative to baseDirectory **/
	var stylesheet			: String; // stylesheet.css
	var baseDirectory		: String; // /my/path/html/ (index.html, all_classes.html etc)
	var packageDirectory	: String; // /my/path/packages/ (pkg/path/package.html)
	var typeDirectory		: String; // /my/path/types/ (pkg/path/Class.html)

	var noPrompt			: Bool; // turn off prommpting (not implemented)
	var installImagesDir	: Bool;
	var installCssFile		: Bool;

	var title 				: String;
	var subtitle 			: String;
	/** true if generating developer documentation (any of showPrivate* switches set) **/
	var developer			: Bool;
	/** A list of all platforms being generated for **/
	var platforms			: List<String>;
	/** text to add to the bottom of each Type page **/
	var footerText			: Html;
	var headerText			: Html;

	/** generate todo file? **/
	var generateTodo		: Bool;
	var todoLines			: Array<{link: Link, message:String}>;
	var todoFile			: String;

	////////////////////////////////////////
	//// used primarily for web config /////
	/** Base path to the xml files in files **/
	var xmlBasePath			: String;
	/** files to load **/
	var files				: Array<{name:String, platform:String, remap:String}>;
// 	var rendered			: Hash<String>; // rendered html by path
	/** password for ?reload and ?showconfig **/
	var webPassword			: String;
	var ignoreRoot			: Bool;
};

typedef BuildData = {
	var date : String;
	var number : String;
	var comment : Html; // raw comment
};

typedef MetaData = {
	/**
		Short date for <META NAME="date" CONTENT="2009-01-23">
	**/
	var date			: String;
	/**
		Holds an array of keywords, first of which is type path [interface|class|enum]. <META NAME="keywords" CONTENT="haxe.Serializer class">
	**/
	var keywords		: Array<String>;
	/**
		Relative path to the stylesheet. <LINK REL ="stylesheet" TYPE="text/css" HREF="../../stylesheet" TITLE="Style">
	**/
	var stylesheet		: String;
};

typedef DocsContext = {
	/** Html block for everything not a tag **/
	var comments			: Html;
	var authors				: Array<Html>;
	/** method/class/whatever is deprectated **/
	var deprecated			: Bool;
	/** Set to "" or a message if deprecated is true **/
	var deprecatedMsg		: Html; // deprecation text
	var params				: Array<{ arg : Html, desc : Html }>;
	var requires			: Array<Html>;
	var returns				: Array<Html>;
	var see					: Array<Html>;
	var since				: Array<Html>;
	var throws				: Array<{ name : Html, uri : Html, desc : Html}>;
	var todos				: Array<Html>;
	var typeParams			: Array<{ arg : Html, desc : Html }>;
	var version				: Array<Html>;
	/** @private tag */
	var forcePrivate		: Bool;
};

typedef PackageContext = {
	var name				: String;	// short name
	var full				: String;	// full dotted name

	var rootRelative		: String; // ../../ back to /packages
	var packageUri			: String; // packages/pkg/path/package.html
	var types				: Array<Ctx>;

	// Filesystem paths.
	/** Filesystem path to types **/
	var resolvedTypeDir		: String;
	/** filesystem path to package files **/
	var resolvedPackageDir	: String;

	var meta				: MetaData;
	/**
		These 2 exist only at the point the structure is passed to the
		template generator
	var build				: BuildData;
	var config				: Config;
	**/
};

/**
	This is the context passed to the template file for
	index, overview, all_packages and all_classes generation.
**/
typedef IndexContext = {
	var meta		: MetaData;
	var config		: Config;
	var build		: BuildData;
}

typedef FileInfo = {
	// example 1) public a.b.C 2) private a.b.D defined in a.b.C 3)flash9.MyClass
	// TypeInfos.path: 1) a.b.C 2) a.b._C.D
	var name			: String; // Short name.  1) C 2) D 3) MyClass
	var nameDots		: String; // Dotted filename 1) a.b.C 2) a.b._C.D 3) flash.MyClass
	var packageDots		: String; // Dotted package name. 1) a.b 2) a.b._C 3) flash
	var subdir			: String; // Relative subdir for html 1) a/b/ 2) a/b/_C/ 3) flash9
	var rootRelative	: String; // Path to root
}
