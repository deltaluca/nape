run: build
	debugfp StressPyramid.swf

build:
	haxe 		-cp "/" -cp . -cp ../common 		-lib nape -D NAPE_RELEASE_BUILD -D NAPE_ARRAYS	-swf-header 500:500:60:333333 		-swf-version 11 		-main StressPyramid 		-swf StressPyramid.swf
