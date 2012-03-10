run: build
	fp WaterBalls.swf 

build:
	haxe -cp "/" -lib nape -D NAPE_RELEASE_BUILD -swf-header 800:400:60:333333 -swf WaterBalls.swf -cp . -cp ../common -main WaterBalls -swf-version 11 --dead-code-elimination
