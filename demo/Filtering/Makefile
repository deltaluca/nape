NAPELIB=../../bin/release/release_nape.swc

run: build
	fp Filtering.swf

runas3: buildas3
	fp Filtering.swf

build:
	haxe 		-cp "/" -cp . -cp ../common 		-lib nape \
	-D NAPE_RELEASE_BUILD \
    -swf-header 600:450:60:333333 		-swf-version 10.1 		-main Filtering 		-swf Filtering.swf --dead-code-elimination

buildas3:
	mxmlc Filtering.as -source-path ../common -source-path . --include-libraries $(NAPELIB) --static-link-runtime-shared-libraries -debug
