![](http://deltaluca.me.uk/napelogo.jpg)

# Where to download

Available on github are the .cx source-code requiring my caxe preprocessor.

From my website (http://deltaluca.me.uk/docnew) are available pre-processed .hx source-code, as well as pre-built AS3 .swcs and haxe .swfs for use with -swf-lib.

From haxelib, you can also install nape with 'haxelib install nape' or when updating, 'haxelib upgrade'.

# Which build to use.

In any case, but especcialy when using pre-built binaries you have the option of 3 build versions (ignoring flashplayer9, flashplayer10+ versions)

* In general, you should ALWAYS be using the debug builds (which requires no additional haxe compiler arguments) which includes many, many inbuilt error catching statements to ensure you are using nape correctly and being informed of bugs in your code with respect to nape.
* When releasing a final product, you can use the release builds (-D NAPE_RELEASE_BUILD for haxe) which removes all of these error catching statements.
* If helping to track down a bug, you can use the assert builds (-D NAPE_NO_INLINE -D NAPE_ASSERT; can also use --no-inline if not creating a binary) which includes thousands of internal assertions.

If compiling a modified nape binary, you will need to use my 'flib' tool on github, and use additional haxe arguments -D swc -D flib

The supplied Makefile should work fine under *nix systems, commands will be near identical from windows command line.
