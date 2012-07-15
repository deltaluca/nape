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

import chxdoc.Defines;
import chxdoc.Types;
import haxe.rtti.CType;
import sys.FileSystem;

class ChxDocMain {
	static var proginfo : String;

	public static var buildData : BuildData;

	public static var config : Config =
	{
		versionMajor		: 1,
		versionMinor		: 1,
		versionRevision		: 3,
		buildNumber			: 727,
		verbose				: false,
		rootTypesPackage	: null,
		allPackages			: new Array(),
		allTypes			: new Array(),
		docBuildDate		: Date.now(),
		dateShort			: DateTools.format(Date.now(), "%Y-%m-%d"),
		dateLong			: DateTools.format(Date.now(), "%a %b %d %H:%M:%S %Z %Y"),
		showAuthorTags		: false,
		showPrivateClasses	: false,
		showPrivateTypedefs	: false,
		showPrivateEnums	: false,
		showPrivateMethods	: false,
		showPrivateVars		: false,
		showTodoTags		: false,
		temploBaseDir		: Settings.defaultTemplate,
		temploTmpDir		: "./__chxdoctmp/",
		temploMacros		: "macros.mtt",
		htmlFileExtension	: ".html",

		stylesheet			: "stylesheet.css",

		baseDirectory		: "./docs/",
		packageDirectory	: "./docs/packages/",
		typeDirectory		: "./docs/types/",

		noPrompt			: false, // not implemented
		installImagesDir	: true,
		installCssFile		: true,


		title 				: "Haxe Application",
		subtitle			: "http://www.haxe.org/",
		developer			: false,
		platforms			: new List(),
		footerText			: null,
		headerText			: null,
		generateTodo		: false,
		todoLines			: new Array(),
		todoFile			: "todo.html",

		xmlBasePath			: "",
		files				: new Array(),
		webPassword			: null,
		ignoreRoot			: false,
	};

	static var parser = new haxe.rtti.XmlParser();

	/** the one instance of PackageHandler that crawls the TypeTree **/
	static var packageHandler	: PackageHandler;

	/**
		all package contexts below the root,
		before being transformed into config in stage3
	**/
	static var packageContexts : Array<PackageContext>;


	// These are only used during pass1, and are invalid after
	/** Current package being processed, dotted form **/
	public static var currentPackageDots : String;
	/** Path to ascend to base index directory **/
	public static var baseRelPath		: String;


	public static var println 			: Dynamic->Void;
	public static var print				: Dynamic->Void;

	static var webConfigFile			: String	= ".chxdoc.hsd";
	public static var writeWebConfig	: Bool		= false;


	//////////////////////////////////////////////
	//               Pass 1                     //
	//////////////////////////////////////////////
	static function pass1(list: Array<TypeTree>) {
		for( entry in list ) {
			switch(entry) {
			case TPackage(name, full, subs):
				var ocpd = currentPackageDots;
				var obrp = baseRelPath;
				//path += name + "/";
				if(name != "root") {
					currentPackageDots = full;
					baseRelPath = "../" + baseRelPath;
				} else {
					currentPackageDots = "";
					baseRelPath = "";
				}
				var ctx = packageHandler.pass1(name, full, subs);
				if(name == "root")
					config.rootTypesPackage = ctx;
				else
					packageContexts.push(ctx);

				pass1(subs);

				baseRelPath = obrp;
				currentPackageDots = ocpd;
			// the rest are handled by packageHandler
			default:
			}
		}
	}

	//////////////////////////////////////////////
	//               Pass 2                     //
	//////////////////////////////////////////////
	/**
		<pre>
		Types -> create documentation
		Package -> Make directories
		</pre>
	**/
	static function pass2() {
		packageContexts.sort(PackageHandler.sorter);
		packageHandler.pass2(config.rootTypesPackage);
		for(i in packageContexts)
			packageHandler.pass2(i);
		// these were added in reverse order since DocProcessor does it that way
		config.todoLines.reverse();
	}


	//////////////////////////////////////////////
	//               Pass 3                     //
	//////////////////////////////////////////////
	/**
		<pre>
		Types	-> Resolve all super classes, inheritance, subclasses
		Package -> Prune filtered types
				-> Sort classes
				-> Add all types to main types
		</pre>
	**/
	static function pass3() {
		if( !config.ignoreRoot )
			packageHandler.pass3(config.rootTypesPackage);

		for(i in packageContexts)
			packageHandler.pass3(i);

		config.allTypes.sort(function(a,b) {
			return Utils.stringSorter(a.path, b.path);
		});
		config.allPackages.sort(function(a,b) {
			return Utils.stringSorter(a.full, b.full);
		});

		packageContexts = null;
	}

	public static function registerType(ctx : Ctx) : Void
	{
		config.allTypes.push(ctx);
	}

	public static function registerPackage(pkg : PackageContext) : Void
	{
		if(pkg.full == "root types") {
			config.rootTypesPackage = pkg;
			return;
		}
		else {
			config.allPackages.push(pkg);
		}
	}

	public static function registerTodo(pkg:PackageContext, ctx:Ctx, msg: String) {
		if(!config.generateTodo)
			return;
		var parentCtx = CtxApi.getParent(ctx, true);
		var childCtx = ctx;

		if(parentCtx == null) {
			parentCtx = ctx;
			childCtx = null;
		}

		var dots = parentCtx.packageDots;
		if(dots == null)
			dots = pkg.full;

		var href = "types/" +
				Utils.addSubdirTrailingSlash(dots.split(".").join("/")) +
				parentCtx.name +
				config.htmlFileExtension +
				CtxApi.makeAnchor(childCtx);

		var linkText = parentCtx.nameDots;

		config.todoLines.push({
			link: Utils.makeLink(
					href,
					linkText,
					"todoLine"
				),
			message: msg,
		});
	}

	//////////////////////////////////////////////
	//               Pass 4                     //
	//////////////////////////////////////////////
	/**
		Write everything
	**/
	static function pass4() {
		if( !config.ignoreRoot )
			packageHandler.pass4(config.rootTypesPackage);
		for(i in config.allPackages)
			packageHandler.pass4(i);


		var a = ["index", "overview", "all_packages", "all_classes"];
		if(config.generateTodo)
			a.push("todo");

		for(i in a) {
			if( config.ignoreRoot ) config.rootTypesPackage = null;
			Utils.writeFileContents(
				config.baseDirectory + i + config.htmlFileExtension,
				execBaseTemplate(i)
			);
		}
	}

	static function execBaseTemplate(s : String, ?cfg:Dynamic) : String {
		if(!isBaseTemplate(s))
			fatal(s + " is not a valid file");
		var c : Dynamic = config;
		if(cfg != null)
			c = cfg;
		var t = new mtwin.templo.Loader(s+".mtt");
		var metaData = {
			date : config.dateShort,
			keywords : new Array<String>(),
			stylesheet : config.stylesheet,
		};
		metaData.keywords.push("");
		var context : IndexContext = {
			meta		: metaData,
			build 		: buildData,
			config		: c,
		};
		return t.execute(context);
	}

	/**
		Returns true if the provided name is a valid base directory
		templated
		@param s Base file name without any extension (ie. 'index' not 'index.mtt' or 'index.html')
		@return true if s is a valid name.
	**/
	static function isBaseTemplate(s : String) : Bool {
		switch(s) {
		case "index":
		case "overview":
		case "all_packages":
		case "all_classes":
		case "todo":
		case "config":
		default:
			return false;
		}
		return true;
	}


	//////////////////////////////////////////////
	//               Utilities                  //
	//////////////////////////////////////////////
	/**
		Locate a type context from it's full path in all
		packages. Can not be used until after pass 1.
		@throws String when type not found
	**/
	public static function findType( path : String ) : Ctx {
		var parts = path.split(".");
		var name = parts.pop();
		var pkgPath = parts.join(".");

		var pkg : PackageContext = findPackage(pkgPath);
		if(pkg == null)
			throw "Unable to locate package " + pkgPath + " for "+ path;

		for(ctx in pkg.types) {
			if(ctx.path == path)
				return ctx;
		}
		throw "Could not find type " + path;
	}

	/**
		Find a package by it's full path. Do not include a Type name.
		@param path Package path
		@returns null or PackageContext
	**/
	public static function findPackage(path : String) : PackageContext {
		if(path == "" || path == "root types")
			return config.rootTypesPackage;
		var p = config.allPackages;
		// before stage3, we have to look in unfiltered packages
		if(packageContexts != null && packageContexts.length > 0)
			p = packageContexts;
		if(p == null)
			return null;
		for(i in p) {
			if(i.full == path)
				return i;
		}
		return null;
	}


	//////////////////////////////////////////////
	//              Main                        //
	//////////////////////////////////////////////
	public static function main() {
		chx.Log.redirectTraces(true);

		if( neko.Web.isModNeko )
			setNullPrinter();
		else
			setDefaultPrinter();

		proginfo = "ChxDoc Generator "+
			makeVersion() +
			" - (c) 2008-2012 Russell Weir";

		buildData = {
			date: config.dateShort,
			number: Std.string(config.buildNumber),
			comment: "<!-- Generated by chxdoc (build "+config.buildNumber+") on "+config.dateShort+" -->",
		};

		print(proginfo + "\n");
		initDefaultPaths();

		parseArgs();

		initTemplo();

		if( neko.Web.isModNeko ) {
			checkAllPaths();
			neko.Web.cacheModule(webHandler);
			webHandler();
		}
		else {
			loadXmlFiles();
			checkAllPaths();
			generate();
			installTemplate();
		}
	}

	static function webHandler() : Void {
		if(config == null)
			fatal("Config is not set");

		var modPath = function(s) {
			if(s == null)
				s = "";
			if(s.charAt(0) != "/")
				return neko.Web.getCwd() + s;
			return s;
		}
		var updatePaths = function() {
			config.temploBaseDir = modPath(config.temploBaseDir);
			config.temploTmpDir = modPath(config.temploTmpDir);
			initTemplo();
		}
		var updateXmlPaths = function() {
			config.xmlBasePath = null;
			for(i in config.files)
				i.name = modPath(i.name);
		}

		var params = neko.Web.getParams();
		if( params.get("showconfig") != null) {
			setDefaultPrinter();
			if(config.webPassword != params.get("password")) {
				logError("Not authorized");
				return;
			}
			var cfg = makeViewableConfig();
			updatePaths();
			print(execBaseTemplate("config", cfg));
			return;
		}

		updatePaths();
		if( params.get("reload") != null ) {
			if(config.webPassword != params.get("password")) {
				logError("Not authorized");
				return;
			}
			updateXmlPaths();
			loadXmlFiles();
			writeWebConfig = true;
			generate();
		}
		setDefaultPrinter();

		var base = params.get("base");
		if(base == null || base == "")
			base = "index";
		// index, overview etc.
		if(isBaseTemplate(base)) {
			print(execBaseTemplate(base));
		}
		else {
			if(base == "types") {
				var path = params.get("path").split("/").join(".");
				try {
					var ctx : Ctx = findType(path);
					print(TypeHandler.execTemplate(ctx));
				} catch(e:String) {
					print("Unable to find type " + path);
				}
			}
			else if(base == "packages") {
				var parts = params.get("path").split("/");
				if(parts[parts.length-1] == "package")
					parts.pop();
				var path = parts.join(".");
				var pkg = findPackage(path);
				if(pkg != null)
					print(PackageHandler.execTemplate(pkg));
				else
					print("Could not find package " + path);
			}
			else
				print("File not found : " + base);
		}
	}

	static function generate() {
		packageHandler = new PackageHandler();
		packageContexts = new Array<PackageContext>();

		// These need to be reset for web regeneration
		config.rootTypesPackage = null;
		config.allPackages = new Array();
		config.allTypes = new Array();
		config.docBuildDate = Date.now();
		config.dateShort = DateTools.format(Date.now(), "%Y-%m-%d");
		config.dateLong = DateTools.format(Date.now(), "%a %b %d %H:%M:%S %Z %Y");
		config.todoLines = new Array();

		baseRelPath = "";
		pass1([TPackage("root", "root types", parser.root)]);
		print(".");
		pass2();
		print(".");
		pass3();
		print(".");
		if( !neko.Web.isModNeko && !writeWebConfig)
			pass4();
		if(writeWebConfig) {
			var p = webConfigFile;
			if(neko.Web.isModNeko)
				p = neko.Web.getCwd() + webConfigFile;
			var f = neko.io.File.write(p,false);
			var ser = new chx.Serializer(f);
			ser.preSerializeObject = function(o) {
				if(Reflect.hasField(o, "originalDoc")) {
					untyped o.originalDoc = null;
				}
			}
			ser.serialize(config);
			f.close();
		}
		print("\nComplete.\n");
	}


	static function initDefaultPaths() {
		config.baseDirectory = neko.Sys.getCwd() + "docs/";
		config.packageDirectory = config.baseDirectory + "packages/";
		config.typeDirectory = config.baseDirectory + "types/";
	}

	static function checkAllPaths() {
		initTemplo();

		// Add trailing slashes to all directory paths
		config.baseDirectory = Utils.addSubdirTrailingSlash(config.baseDirectory);
		config.packageDirectory = config.baseDirectory + "packages/";
		config.typeDirectory = config.baseDirectory + "types/";

		if( neko.Web.isModNeko || writeWebConfig )
			return;

		Utils.createOutputDirectory(config.baseDirectory);
		Utils.createOutputDirectory(config.packageDirectory);
		Utils.createOutputDirectory(config.typeDirectory);
	}

	static function installTemplate() {
		var targetImgDir = config.baseDirectory + "images";
		/*
		if(!FileSystem.exists(targetImgDir)) {
			var copyImgDir = config.installImagesDir;
			var srcDir = config.temploBaseDir + "images";
			if(FileSystem.exists(srcDir)) {
				if(!copyImgDir && !config.noPrompt) {
					//copyImgDir = system.Terminal.promptYesNo("Install the images directory from the template?", true);
				}
			}
			if(copyImgDir) {
				// cp -R srcDir config.baseDirectory
			}
		}
		*/

		if(config.installImagesDir) {
			Utils.createOutputDirectory(targetImgDir);
			var srcDir = config.temploBaseDir + "images";
			if(FileSystem.exists(srcDir) && FileSystem.isDirectory(srcDir)) {
				targetImgDir += "/";
				var entries = FileSystem.readDirectory(srcDir);
				for(i in entries) {
					var p = srcDir + "/" + i;
					if(FileSystem.isDirectory(p))
						continue;
					if(config.verbose)
						println("Installing " + p + " to " + targetImgDir);
					neko.io.File.copy(p, targetImgDir + i);
				}
			} else {
				if(config.verbose)
					logWarning("Template " + config.temploBaseDir + " has no 'images' directory");
			}
		}

		if(config.installCssFile) {
			var srcCssFile = config.temploBaseDir + "stylesheet.css";
			if(FileSystem.exists(srcCssFile)) {
				var targetCssFile = config.baseDirectory + config.stylesheet;
				if(config.verbose)
					println("Installing " + srcCssFile + " to " + targetCssFile);
				neko.io.File.copy(srcCssFile, targetCssFile);
			} else {
				if(config.verbose)
					logWarning("Template " + config.temploBaseDir + " has no stylesheet.css");
			}

			var srcJsFile = config.temploBaseDir + "chxdoc.js";
			if(FileSystem.exists(srcJsFile)) {
				var targetJsFile = config.baseDirectory + "chxdoc.js";
				if(config.verbose)
					println("Installing " + srcJsFile + " to " + targetJsFile);
				neko.io.File.copy(srcJsFile, targetJsFile);
			} else {
				if(config.verbose)
					logWarning("Template " + config.temploBaseDir + " has no chxdoc.js");
			}
		}
	}

	/**
		Initializes Templo, exiting if there is any error.
	**/
	static function initTemplo() {
		config.temploBaseDir = Utils.addSubdirTrailingSlash(config.temploBaseDir);
		config.temploTmpDir = Utils.addSubdirTrailingSlash(config.temploTmpDir);

		mtwin.templo.Loader.BASE_DIR = config.temploBaseDir;
		mtwin.templo.Loader.TMP_DIR = config.temploTmpDir;
		mtwin.templo.Loader.MACROS = config.temploMacros;

		if(! neko.Web.isModNeko && ! writeWebConfig ) {
			var tmf = config.temploBaseDir + config.temploMacros;
			if(!FileSystem.exists(tmf))
				fatal("The macro file " + tmf + " does not exist.");
			Utils.createOutputDirectory(config.temploTmpDir);
		}
	}

	static function parseArgs() {
		if( neko.Web.isModNeko ) {
			var data : String =
				try
					neko.io.File.getContent(neko.Web.getCwd()+webConfigFile)
				catch(e:Dynamic) {
					fatal("There is no configuration data. Please create one with --writeWebConfig");
					null;
				}
			var cfg : Dynamic =
				try
					chx.Unserializer.run ( data )
				catch( e : Dynamic ) {
					fatal("Error unserializing config data: " + Std.string(e));
					null;
				}
			config = cfg;
			return;
		}
		var expectOutputDir = false;
		var expectFilter = false;

		for( x in neko.Sys.args() ) {
			if( x == "-f" )
				expectFilter = true;
			else if( expectFilter ) {
				Utils.addFilter(x);
				expectFilter = false;
			}
			else if( x == "-o")
				expectOutputDir = true;
			else if( expectOutputDir ) {
				config.baseDirectory = x;
				config.baseDirectory = StringTools.replace(config.baseDirectory,"\\", "/");
				if(config.baseDirectory.charAt(0) != "/") {
					config.baseDirectory = neko.Sys.getCwd() + config.baseDirectory;
				}
				expectOutputDir = false;
			}
			else if( x == "-v")
				config.verbose = true;
			else if( x == "--writeWebConfig")
				writeWebConfig = true;
			else if( x.indexOf("=") > 0) {
				var parts = x.split("=");
				if(parts.length < 2) {
					fatal("Error with parameter " + x);
				}
				if(parts.length > 2) {
					var zero = parts.shift();
					var rest = parts.join("=");
					parts = [zero, rest];
				}
				switch(parts[0]) {
				case "--developer":
					var show = getBool(parts[1]);
					config.showAuthorTags = show;
					config.showPrivateClasses = show;
					config.showPrivateTypedefs = show;
					config.showPrivateEnums = show;
					config.showPrivateMethods = show;
					config.showPrivateVars = show;
					config.showTodoTags = show;
					config.generateTodo = show;
				case "--exclude":
					var opts = parts[1].split(",");
					for(p in opts) {
						p = StringTools.trim(p);
						Utils.addFilter(p);
					}
				case "--footerText":
					config.footerText = parts[1];
				case "--footerTextFile":
					try {
						config.footerText = neko.io.File.getContent(parts[1]);
					} catch(e : Dynamic) {
						fatal("Unable to load footer file " + parts[1]);
					}
				case "--headerText":
					config.headerText = parts[1];
				case "--headerTextFile":
					try {
						config.headerText = neko.io.File.getContent(parts[1]);
					} catch(e : Dynamic) {
						fatal("Unable to load header file " + parts[1]);
					}
				case "--generateTodoFile":
					config.generateTodo = getBool(parts[1]);
				case "--ignoreRoot":
					config.ignoreRoot = getBool( parts[1] );
				case "--includeOnly":
					var opts = parts[1].split(",");
					for(p in opts) {
						p = StringTools.trim(p);
						Utils.addAllowOnly(p);
					}
				case "--installTemplate":
					var i = getBool(parts[1]);
					config.installImagesDir = i;
					config.installCssFile = i;
				case "--macroFile": config.temploMacros = parts[1];
				case "--showAuthorTags": config.showAuthorTags = getBool(parts[1]);
				case "--showPrivateClasses": config.showPrivateClasses = getBool(parts[1]);
				case "--showPrivateTypedefs": config.showPrivateTypedefs = getBool(parts[1]);
				case "--showPrivateEnums": config.showPrivateEnums = getBool(parts[1]);
				case "--showPrivateMethods": config.showPrivateMethods = getBool(parts[1]);
				case "--showPrivateVars": config.showPrivateVars = getBool(parts[1]);
				case "--showTodoTags": config.showTodoTags = getBool(parts[1]);
				case "--stylesheet": config.stylesheet = parts[1];
				case "--subtitle": config.subtitle = parts[1];
				case "--templateDir", "--template": config.temploBaseDir = parts[1];
				case "--title": config.title = parts[1];
				case "--tmpDir": config.temploTmpDir = parts[1];
				case "--webPassword": config.webPassword = parts[1];
				case "--writeWebConfig": writeWebConfig = getBool(parts[1]);
				case "--xmlBasePath": config.xmlBasePath = parts[1];
				}
			}
			else if( x == "--help" || x == "-help")
				usage(0);
			else {
				var f = x.split(",");
				config.files.push({name:f[0], platform:f[1], remap:f[2]});
			}
		}

		if(writeWebConfig && config.htmlFileExtension != "") {
			if(config.htmlFileExtension != "") {
				logWarning("Html file extension ignored for web configurations");
				config.htmlFileExtension = "";
			}
			if(config.installImagesDir || config.installCssFile) {
				logWarning("Install templates manually for web configurations");
			}
		}

		config.todoFile = "todo" + config.htmlFileExtension;

		if(	config.showPrivateClasses ||
			config.showPrivateTypedefs ||
			config.showPrivateEnums ||
			config.showPrivateMethods ||
			config.showPrivateVars)
				config.developer = true;


	}

	static function getBool(s : String) : Bool {
		if(s == "1" || s == "true" || s == "yes")
			return true;
		return false;
	}

	static function usage(exitVal : Int) {
		println(" Usage : chxdoc [options] [xml files]");
		println(" Options:");
		println("\t-f filter Add a package or class filter");
		println("\t-o outputdir Sets the output directory (defaults to ./html)");
		println("\t--developer=[true|false] Shortcut to showing all privates, if true");
		println("\t--footerText=\"text\" Text that will be added to footer of Type pages");
		println("\t--footerTextFile=/path/to/file Type pages footer text from file");
		println("\t--headerText=\"text\" Text that will be added to header of Type pages");
		println("\t--headerTextFile=/path/to/file Type pages header text from file");
		println("\t--generateTodoFile=[true|false] Generate the todo.html file");
		println("\t--installTemplate=[true|false] Install stylesheet and images from template");
		println("\t--includeOnly=[comma delimited packages and classes] Output only for listed classes and packages");
		println("\t--macroFile=file.mtt Temploc macro file. (default macros.mtt)");
		println("\t--showAuthorTags=[true|false] Toggles showing @author contents");
		println("\t--showPrivateClasses=[true|false] Toggle private classes display");
		println("\t--showPrivateTypedefs=[true|false] Toggle private typedef display");
		println("\t--showPrivateEnums=[true|false] Toggle private enum display");
		println("\t--showPrivateMethods=[true|false] Toggle private method display");
		println("\t--showPrivateVars=[true|false] Toggle private var display");
		println("\t--showTodoTags=[true|false] Toggle showing @todo tags in type documentation");
		println("\t--stylesheet=file Sets the stylesheet relative to the outputdir");
		println("\t--subtitle=string Set the package subtitle");
		println("\t--template=path Path to template (.mtt) directory (default ./templates)");
		println("\t--title=string Set the package title");
		println("\t--tmpDir=path Path for tempory file generation (default ./tmp)");
		println("\t-v Turns on verbose mode");
		println("\t--webPassword=[pass] Sets a web password for ?reload and ?showconfig");
		println("\t--writeWebConfig Parses everything, serializes and outputs "+ webConfigFile);
		println("\t--xmlBasePath=path Set a default path to xml files");
		println("\t--exclude=[comma,delimited,pkgnames] Exclude packages from being generated");
		println("\t--ignoreRoot=[true|false] Toggle display of root classes");
		println("");
		println(" XML Files:");
		println("\tinput.xml[,platform[,remap]");
		println("\tXml files are generated using the -xml option when compiling haxe projects. ");
		println("\tplatform - generate docs for a given platform" );
		println("\tremap - change all references of 'remap' to 'package'");
		println("\n Sample usage:");
		println("\tchxdoc flash9.xml,flash,flash9 php.xml,php");
		println("\t\tWill transform all references to flash.* to flash9.*");
		println("\tchxdoc -o Doc --includeOnly=mypackage.*,Int --developer=true --generateTodoFile=true --showTodoTags=true neko.xml,neko");
		println("\t\tGenerates developer docs for mypackage.* and the Int class only, generating the TODO file as well as showing @todo\n\t\ttags in user docs. The output is built in the 'Doc' directory.");
		println("");
		if(! neko.Web.isModNeko )
			neko.Sys.exit(exitVal);
		else
			throw("");
	}

	static function loadXmlFiles() {
		config.platforms = new List();
		if(config.xmlBasePath == null)
			config.xmlBasePath = "";
		for(i in config.files) {
			loadFile(Utils.addSubdirTrailingSlash(config.xmlBasePath) + i.name, i.platform, i.remap);
		}
		parser.sort();
		if( parser.root.length == 0 ) {
			println("Error: no xml data loaded");
			usage(1);
		}
	}

	static function loadFile(file : String, platform:String, ?remap:String) {
		var data : String = null;
		try {
			data = neko.io.File.getContent(neko.Sys.getCwd()+file);
		} catch(e:Dynamic) {
			fatal("Unable to load platform xml file " + file);
		}
		var x = Xml.parse(data).firstElement();
		if( remap != null )
			transformPackage(x,remap,platform);

		parser.process(x,platform);
		if(platform != null)
			config.platforms.add(platform);
	}

	static function transformPackage( x : Xml, remap, platform ) {
		switch( x.nodeType ) {
		case Xml.Element:
			var p = x.get("path");
			if( p != null && p.length > platform.length && p.substr(0,platform.length) == platform )
				x.set("path", remap + "." + p.substr(platform.length+1));
			for( x in x.elements() )
				transformPackage(x, remap, platform);
		default:
		}
	}

	public static function logDebug(msg:String, ?pkg:PackageContext, ?ctx : Ctx, ?pos:haxe.PosInfos) {
		if( !config.verbose ) return;
		if(pkg != null) {
			msg += " in package " + pkg.full;
		}
		if(ctx != null) {
			msg += " in " + ctx.name;
		}
		msg += " ("+ pos.fileName+":"+pos.lineNumber+")";
		println("DEBUG: " + msg);
	}

	public static function logInfo(msg:String, ?pkg:PackageContext, ?ctx : Ctx, ?pos:haxe.PosInfos) {
		if( !config.verbose ) return;
		if(pkg != null) {
			msg += " in package " + pkg.full;
		}
		if(ctx != null) {
			msg += " in " + ctx.name;
		}
		println("INFO: " + msg);
	}

	/**
	@todo Ctx may be a function, so we need the parent ClassCtx. Requires adding
			'parent' to Ctx typedef
	**/
	public static function logWarning(msg:String, ?pkg:PackageContext, ?ctx : Ctx, ?pos:haxe.PosInfos) {
		if( !config.verbose ) return;
		if(pkg != null) {
			msg += " in package " + pkg.full;
		}
		if(ctx != null) {
			msg += " in " + ctx.name;
		}
		println("WARNING: " + msg);
	}

	public static function logError(msg:String, ?pkg:PackageContext, ?ctx : Ctx, ?pos:haxe.PosInfos) {
		setDefaultPrinter();
		if(pkg != null) {
			msg += " in package " + pkg.full;
		}
		if(ctx != null) {
			msg += " in " + ctx.name;
		}
		println("ERROR: " + msg);
	}

	public static function fatal(msg:String, exitVal:Int=0, ?pos:haxe.PosInfos) {
		setDefaultPrinter();
		if(exitVal == 0)
			exitVal = 1;
		println("FATAL: " + msg);
		if(! neko.Web.isModNeko )
			neko.Sys.exit(exitVal);
		else
			throw "";
	}

	/**
		Sets default print and println functions by platform
	**/
	static function setDefaultPrinter() {
	#if neko
		if( neko.Web.isModNeko )
			println = function(v) { neko.Lib.print(v); neko.Lib.println("<BR />"); }
		else
			println = neko.Lib.println;
		print = neko.Lib.print;
	#else
	#error
	#end
	}

	/**
		Sets null sink printing
	**/
	static function setNullPrinter() {
		print = function (v) {};
		println = function (v) {};
	}

	static function makeViewableConfig() : Array<{name:String, value: String}> {
		var rv = new Array();
		var addCfg = function(s:String) {
			rv.push({ name:s, value : Std.string(Reflect.field(config, s)) });
		}
		rv.push({ name: "ChxDoc", value: makeVersion() });
		rv.push({ name: "Generated", value: config.dateLong});
		for(i in [
			"stylesheet",
			"temploBaseDir",
			"temploTmpDir",
			"temploMacros",
			"xmlBasePath"
			])
			addCfg(i);
		for(i in config.files) {
			var s :String = i.name + "," + i.platform + "," + i.remap;
			rv.push({ name: "XML file", value: s });
		}
		return rv;
	}

	/**
		Dot formatted version string
		@returns String formatted version number ie 1.3.1
	**/
	static function makeVersion() : String {
		return config.versionMajor+ "."+
			config.versionMinor + "."+
			config.versionRevision;
	}
}
