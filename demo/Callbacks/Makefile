run: build
	debugfp Callbacks.swf

build:
	haxe -cp "/" -lib nape -swf-header 800:600:60:333333 -swf Callbacks.swf -cp . -cp ../common -main Callbacks -swf-version 10.1 --dead-code-elimination -debug -D NAPE_ASSERT
