run: build
	fp Callbacks.swf

build:
	haxe -cp "/" -lib nape -swf-header 800:600:60:333333 -swf Callbacks.swf -cp . -cp ../common -main Callbacks -swf-version 10.1 --dead-code-elimination -D NAPE_RELEASE_BUILD

.PHONY: cpp
cpp:
	haxe -cp "/" -lib nape -main Callbacks -cpp cpp --times --remap flash:nme -lib nme -cp ../common
	./cpp/Callbacks
