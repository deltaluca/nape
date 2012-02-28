NAPELIB = $(NAPE)/haxe_release_nape.swf

run: build
	fp PerlinSquares.swf 

build:
	haxe -cp "/" -swf-lib $(NAPELIB) -swf-header 400:300:60:ffffff -swf PerlinSquares.swf -cp . -cp ../common -main PerlinSquares -swf-version 11 
