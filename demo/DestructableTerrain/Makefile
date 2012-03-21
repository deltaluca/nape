run: build
	fp DestructableTerrain.swf

build:
	haxe 		-cp "/" -cp . -cp ../common 		-lib nape -D NAPE_RELEASE_BUILD		-swf-header 800:600:60:333333 		-swf-version 10 		-main DestructableTerrain 		-swf DestructableTerrain.swf --dead-code-elimination
