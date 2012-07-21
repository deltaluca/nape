run: build
	fp DestructableTerrain.swf

build:
	haxe 		-cp "/" -cp . -cp ../common 		-lib nape 		-swf-header 800:600:60:333333 		-swf-version 10.1 		-main DestructableTerrain 		-swf DestructableTerrain.swf -D NAPE_RELEASE_BUILD

.PHONY: cpp
cpp:
	haxe -cp "/" -lib nape -main DestructableTerrain -cpp cpp --times --remap flash:nme -lib nme -cp ../common
	./cpp/DestructableTerrain
