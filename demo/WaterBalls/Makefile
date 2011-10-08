NAPELIB = $(NAPE)/haxe_debug_nape.swf

build:
	haxe -cp "/" -swf-lib $(NAPELIB) -swf-header 800:400:60:333333 -swf WaterBalls.swf -cp . -cp ../common -main WaterBalls -swf-version 11
	fp WaterBalls.swf 
