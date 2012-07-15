import sys.FileSystem;

class Run {

	static var sys:String = neko.Sys.systemName();
	static var installdir:String;
	static var builddir:String;
	static var curdir:String;
	static var print:Dynamic->Void = neko.Lib.print;
	static var println:Dynamic->Void = neko.Lib.println;

	static function main() {
		var args = neko.Sys.args().slice(0);
		//trace(args);
		installdir = args.pop();
		curdir = installdir;
		var cmd = args.shift();
		builddir = makePath(neko.Sys.getCwd());
		//trace("cmd: " + cmd);
		//trace("installdir: '"+installdir+"'");
		//trace("build dir: '"+builddir+"'");
		//trace("Environment:");
		//trace(neko.Sys.environment());
		switch(cmd) {
		case "--help":
			usage();
		case "compile":
			compile();
		case "install":
			compile();
			var p = args.shift();
			if(p != null) {
				installdir = makePath(p);
				if(installdir.substr(0,1) != "/")
					installdir = curdir + installdir;
			}
			try {
				installdir = makePath(installdir);
				compile();
				makeExe("chxtemploc");
				makeExe("chxdoc");
			} catch(e:Dynamic) {
				neko.Sys.setCwd(curdir);
				neko.Lib.rethrow(e);
			}
			neko.Sys.setCwd(curdir);
		default:
			usage();
		}
	}

	static function usage() {
		println("haxelib run chxdoc [compile | install [installpath]]");
		println("compile - will just run the compile target");
		println("install - will compile and install to the current directory");
		println("          or to the provided installpath");
	}

	static function makePath(p:String) : String {
		var s = StringTools.replace(p, "\\", "/");
		if(s.length == 0)
			s = "/";
		if(s.substr(-1,1) != "/")
			s += "/";
		return s;
	}

	static function compile() {
		neko.Sys.setCwd(builddir);

		if(!FileSystem.exists("chxdoc/Settings.hx")) {
			print(">> Creating Settings.hx...");
			var sp = builddir + "chxdoc/Settings.hx";
			var fp = neko.io.File.write(sp, false);
			var data : String =
"/**
	This class is automatically generated when installing with haxelib
**/
package chxdoc;

class Settings {
	public static var defaultTemplate : String = \""+builddir+"templates/default/\";
}
";
			fp.writeString(data);
			fp.flush();
			fp.close();
			println(" complete");
		}


		print(">> Compiling in " + neko.Sys.getCwd() + "...");
		var p = new neko.io.Process("haxe",["haxelib_build.hxml"]);
		var code = p.exitCode();
		neko.Sys.setCwd(installdir);
		if( code != 0 )  {
			trace(p.stderr.readAll());
			throw "Error while compiling. Check that haxe is installed.";
		}
		println(" complete");
	}		

	static function makeExe(name:String) {
		var exe = if( sys == "Windows" ) name+".exe" else name;
		var nekoname = name + ".n";
		println(">> Installing "+exe+" into " + installdir);
		neko.Sys.setCwd(installdir);
		neko.io.File.copy(builddir+nekoname, installdir+nekoname);
		var p = new neko.io.Process("nekotools",["boot", nekoname]);
		var code = p.exitCode();
		if( code != 0 ) {
			throw "!! Error while creating " + name + " executable";
		}

		FileSystem.deleteFile(nekoname);

		if( sys != "Windows" )
			neko.Sys.command("chmod a+x " + installdir + exe);
		neko.Lib.println("   "+exe+" is now installed");
	}


}
