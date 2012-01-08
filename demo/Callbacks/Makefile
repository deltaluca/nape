NAPELIB = $(NAPE)/haxe_release_nape.swf

run: build
	fp Callbacks.swf

build:
	haxe -cp "/" -swf-lib $(NAPELIB) -swf-header 800:600:60:333333 -swf Callbacks.swf -cp . -cp ../common -main Callbacks -swf-version 11
