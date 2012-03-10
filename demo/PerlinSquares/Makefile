run: build
	fp PerlinSquares.swf 

build:
	haxe -cp "/" -lib nape -D NAPE_RELEASE_BUILD -swf-header 400:300:60:ffffff -swf PerlinSquares.swf -cp . -cp ../common -main PerlinSquares -swf-version 11  --dead-code-elimination
