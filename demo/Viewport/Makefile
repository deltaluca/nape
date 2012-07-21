run: build
	fp Viewport.swf

build:
	haxe 		-cp "/" -cp . -cp ../common 		-lib nape 		-D NAPE_RELEASE_BUILD 		-swf-header 800:600:60:333333 		-swf-version 10 		-main Viewport 		-swf Viewport.swf

.PHONY: cpp
cpp:
	haxe -cp "/" -lib nape -main Viewport -cpp cpp --times --remap flash:nme -lib nme -cp ../common
	./cpp/Viewport
