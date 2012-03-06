NAPELIB = $(NAPE)/haxe_release_nape.swf

run: build
	fp Filtering.swf

build:
	haxe 		-cp "/" -cp . -cp ../common 		-swf-lib $(NAPELIB) 		-swf-header 600:450:60:333333 		-swf-version 11 		-main Filtering 		-swf Filtering.swf
