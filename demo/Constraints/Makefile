run: build
	fp Constraints.swf

build:
	haxe -cp "/" -lib nape -D NAPE_RELEASE_BUILD -swf-header 1200:600:60:333333 -swf Constraints.swf -cp . -cp ../common -main Constraints -swf-version 10.1 --dead-code-elimination

.PHONY: cpp
cpp:
	haxe -cp "/" -lib nape -main Constraints -cpp cpp --times --remap flash:nme -lib nme -cp ../common
	./cpp/Constraints
