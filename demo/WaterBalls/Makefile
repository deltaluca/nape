NAPELIB = $(NAPE)/haxe_debug_nape.swf

run: build
	fp WaterBalls.swf 

build:
	haxe -cp "/" -swf-lib $(NAPELIB) -swf-header 800:400:60:333333 -swf WaterBalls.swf -cp . -cp ../common -main WaterBalls -swf-version 11
