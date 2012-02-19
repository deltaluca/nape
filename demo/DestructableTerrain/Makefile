NAPELIB = $(NAPE)/haxe_release_nape.swf

run: build
	fp DestructableTerrain.swf

build:
	haxe 		-cp "/" -cp . -cp ../common 		-swf-lib $(NAPELIB) 		-swf-header 800:600:60:333333 		-swf-version 11 		-main DestructableTerrain 		-swf DestructableTerrain.swf
