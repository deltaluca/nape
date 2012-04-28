def:
	mkdir -p bin
	haxe -cp . -lib nape -D NAPE_ASSERT -main Unit -swf bin/unit.swf -swf-version 11 -swf-header 600:600:60:ffffff -debug
	debugfp bin/unit.swf

build:
	mkdir -p bin
	haxe -cp . -lib nape -D NAPE_ASSERT -main Unit -cpp bin -debug
