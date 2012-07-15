package chx.sys;

/**
MyTypedef docs
**/
#if flash9
typedef MyTypedef = {
	var flash9Var : Int;
};

#elseif neko
typedef MyTypedef = Null<Int>;

#elseif js
typedef MyTypedef = {
	var jsVar : String;
}
#end
