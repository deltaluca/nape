run: build
	debugfp Callbacks.swf

build:
	haxe -cp "/" -lib nape -D NAPE_ASSERT -D NAPE_ARRAYS -swf-header 800:600:60:333333 -swf Callbacks.swf -cp . -cp ../common -main Callbacks -swf-version 11
