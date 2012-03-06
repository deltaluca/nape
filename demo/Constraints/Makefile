NAPELIB = $(NAPE)/haxe_release_nape.swf

run: build
	fp Constraints.swf 

build:
	haxe -cp "/" -swf-lib $(NAPELIB) -swf-header 1200:600:60:333333 -swf Constraints.swf -cp . -cp ../common -main Constraints -swf-version 11
