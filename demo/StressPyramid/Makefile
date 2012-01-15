NAPELIB = $(NAPE)/haxe_release_nape.swf

run: build
	fp StressPyramid.swf

build:
	haxe 		-cp "/" -cp . -cp ../common 		-swf-lib $(NAPELIB) 		-swf-header 700:500:60:333333 		-swf-version 11 		-main StressPyramid 		-swf StressPyramid.swf
