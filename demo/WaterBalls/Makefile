run: build
	fp WaterBalls.swf

build:
	haxe -cp "/" -lib nape -D NAPE_RELEASE_BUILD -swf-header 800:400:60:333333 -swf WaterBalls.swf -cp . -cp ../common -main WaterBalls -swf-version 10.1 --dead-code-elimination

.PHONY: cpp
cpp:
	haxe -cp "/" -lib nape -main WaterBalls -cpp cpp --times --remap flash:nme -lib nme -cp ../common
	./cpp/WaterBalls
