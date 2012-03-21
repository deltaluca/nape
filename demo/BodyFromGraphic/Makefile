run: build
	fp BodyFromGraphic.swf

build:
	haxe 		-cp "/" -cp . -cp ../common 		-lib nape -D NAPE_RELEASE_BUILD 		-swf-header 600:450:60:333333 		-swf-version 10 		-main BodyFromGraphic 		-swf BodyFromGraphic.swf --dead-code-elimination
