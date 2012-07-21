NAPELIB=../../bin/release/release_nape.swc

run: build
	fp StressPyramid.swf

runas3: buildas3
	fp StressPyramid.swf

build:
	haxe 		-cp "/" -cp . -cp ../common 		-lib nape -D NAPE_RELEASE_BUILD 		-swf-header 500:500:60:333333 		-swf-version 10.1 		-main StressPyramid 		-swf StressPyramid.swf --dead-code-elimination

buildas3:
	mxmlc StressPyramid.as -source-path ../common -source-path . --include-libraries $(NAPELIB) --static-link-runtime-shared-libraries -debug -optimize

.PHONY: cpp
cpp:
	haxe -cp "/" -lib nape -main StressPyramid -cpp cpp --times --remap flash:nme -lib nme -cp ../common
	./cpp/StressPyramid
