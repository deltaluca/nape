run: build
	fp Cutting.swf

build:
	haxe 		-cp "/" -cp . -cp ../common 		-lib nape -D NAPE_RELEASE_BUILD 		-swf-header 600:450:60:333333 		-swf-version 10 		-main Cutting 		-swf Cutting.swf  --dead-code-elimination
