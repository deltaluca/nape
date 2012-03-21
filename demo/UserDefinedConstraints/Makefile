run: build
	fp UserDefinedConstraints.swf

build:
	haxe 		-cp "/" -cp . -cp ../common 		-lib nape -D NAPE_RELEASE_BUILD 		-swf-header 600:450:60:333333 		-swf-version 10 		-main UserDefinedConstraints 		-swf UserDefinedConstraints.swf --dead-code-elimination
