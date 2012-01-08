NAPELIB = $(NAPE)/haxe_assert_nape.swf

run: build
	debugfp Callbacks.swf

build:
	haxe -cp "/" -swf-lib $(NAPELIB) -swf-header 800:600:60:333333 -swf Callbacks.swf -cp . -cp ../common -main Callbacks -swf-version 11 -debug
