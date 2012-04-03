run: build
	fp Callbacks.swf

build:
	haxe -cp "/" -lib nape -D NAPE_RELEASE_BUILD -swf-header 800:600:60:333333 -swf Callbacks.swf -cp . -cp ../common -main Callbacks -swf-version 10.1 --dead-code-elimination
