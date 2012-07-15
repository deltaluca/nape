package chx.sys;

#if (flash9 || neko)
typedef MyTypedef2 = {
#if flash9
	var flash9 : Int;
#elseif neko
	/** In neko, this var holds.. surprise! A float! **/
	var neko : Float;
#else
	var js : Float;
#end
	var allPlatforms : Bool;
};

#else

typedef MyTypedef2 = Int;
#end
